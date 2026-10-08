#!/usr/bin/env bash
# Checks that a deploy of the demo-app org projects succeeded:
#   1. every deployment / statefulset in the namespace finished its rollout
#   2. every pod is ready and none restarted since the deploy
#   3. the public HTTPS endpoints answer 200 with a valid certificate
#   4. an account's site works: its page, its account lookup (and CORS), and
#      the register form's verification by the backend
#   5. no errors in the app, nginx, PostgreSQL and Redis logs since the deploy
#
# usage: ./check-deploy.sh [SINCE]   (default 10m: how far back to look for restarts and errors)
# needs: ssh access to the node, curl, python3
set -uo pipefail

SINCE=${1:-10m}
NODE=${NODE:-root@192.168.1.14}
NAMESPACE=${NAMESPACE:-development}
DOMAIN=${DOMAIN:-appshare.site}
# an existing account's subdomain, for the account site checks
SUBDOMAIN=${SUBDOMAIN:-ngonzalez}
LOKI_ADDR=${LOKI_ADDR:-http://192.168.1.14:3100}
# Loki's gateway asks for a login: user:password, one line
LOKI_CREDENTIALS=${LOKI_CREDENTIALS:-$HOME/.config/loki-credentials}
# frontend (static files: its page), then backend, stream and showcase: their
# health check goes through Cloudflare, nginx-frontend's SNI router, the app's
# nginx and Rails to PostgreSQL
ENDPOINTS=("$DOMAIN/" "api.$DOMAIN/_health" "stream.$DOMAIN/_health" "register.$DOMAIN/_health")
ERRORS='(?i)(error|fatal|exception|panic|refused|timed? ?out|\[(crit|alert|emerg)\])'
# expected: the fast shutdown of a planned PostgreSQL restart disconnects its clients
IGNORE='terminating connection due to administrator command'

failed=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; failed=1; }
kube() { ssh -o BatchMode=yes "$NODE" kubectl -n "$NAMESPACE" "$@"; }

echo "rollouts"
for r in $(kube get deploy,sts -o name); do
  if out=$(kube rollout status "$r" --timeout=10s 2>&1); then ok "$r"; else fail "$r: $(tail -1 <<< "$out")"; fi
done

echo "pods"
since_s=$(( $(sed -E 's/m$/*60/; s/h$/*3600/; s/s$//' <<< "$SINCE") ))
kube get pods -o json | python3 -c '
import json, sys, datetime
since = int(sys.argv[1]); now = datetime.datetime.now(datetime.timezone.utc)
for p in json.load(sys.stdin)["items"]:
    name = p["metadata"]["name"]; problems = []
    for c in p["status"].get("containerStatuses", []):
        cname = c["name"]
        if not c.get("ready"): problems.append(cname + " not ready")
        last = c.get("lastState", {}).get("terminated")
        # a container lost with its node (ContainerStatusUnknown) has no
        # finishedAt: the start time of the current one dates the restart then
        when = last and (last.get("finishedAt") or c.get("state", {}).get("running", {}).get("startedAt"))
        if when and (now - datetime.datetime.fromisoformat(when.replace("Z", "+00:00"))).total_seconds() < since:
            problems.append(cname + " restarted (" + str(last.get("reason")) + ")")
    print(("FAIL " + name + ": " + ", ".join(problems)) if problems else ("ok " + name))
' "$since_s" > /tmp/check-deploy-pods.$$
while read -r status rest; do
  if [ "$status" = ok ]; then ok "$rest"; else fail "$rest"; fi
done < /tmp/check-deploy-pods.$$
rm -f /tmp/check-deploy-pods.$$

echo "endpoints"
for e in "${ENDPOINTS[@]}"; do
  url="https://$e"
  read -r code verify <<< "$(curl -s -o /dev/null -m 10 -w '%{http_code} %{ssl_verify_result}' "$url")"
  if [ "$code" = 200 ] && [ "$verify" = 0 ]; then ok "$url"; else fail "$url: HTTP $code, certificate check $verify"; fi
done

echo "subdomains"
site="https://$SUBDOMAIN.$DOMAIN"
code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$site/")
if [ "$code" = 200 ]; then ok "$site/"; else fail "$site/: HTTP $code"; fi
# the lookup the site's page makes when it starts, from its origin
query='{"operationName":"getAccount","query":"mutation getAccount($subdomain: String) { getAccount(input: {subdomain: $subdomain}) { account { attributes } errors } }","variables":{"subdomain":"'"$SUBDOMAIN"'"}}'
headers=$(mktemp); body=$(mktemp)
curl -s -m 10 -D "$headers" -o "$body" -H 'Content-Type: application/json' -H "Origin: $site" -d "$query" "https://api.$DOMAIN/graphql"
found=$(python3 -c 'import json, sys; print(json.load(sys.stdin)["data"]["getAccount"]["account"]["attributes"]["subdomain"])' < "$body" 2>/dev/null)
if ! grep -qi "^access-control-allow-origin: $site" "$headers"; then
  fail "getAccount: the API doesn't allow $site (CORS)"
elif [ "$found" = "$SUBDOMAIN" ]; then
  ok "getAccount finds $SUBDOMAIN"
else
  fail "getAccount doesn't find $SUBDOMAIN: $(head -c 200 "$body")"
fi
rm -f "$headers" "$body"
# the register form, sent as a browser does: showcase asks the backend to
# verify the details with its registration token (the backend saves
# nothing at this step). A redirect to /validate means the backend answered,
# a 502 that it refused the token or couldn't be reached
jar=$(mktemp); page=$(mktemp)
curl -s -m 10 -c "$jar" -o "$page" "https://register.$DOMAIN/register"
csrf=$(grep -o 'name="authenticity_token" value="[^"]*"' "$page" | head -1 | sed 's/.*value="//; s/"$//')
answer=$(curl -s -m 15 -b "$jar" -o /dev/null -w '%{http_code} %{redirect_url}' "https://register.$DOMAIN/verify_email_address" \
  --data-urlencode "authenticity_token=$csrf" --data-urlencode "user[accountType]=person" \
  --data-urlencode "user[subdomain]=check-deploy-$(openssl rand -hex 4)" --data-urlencode "user[emailAddress]=check-deploy")
case "$answer" in
  "302 https://register.$DOMAIN/validate"*) ok "register: the backend verifies the form" ;;
  *) fail "register: verify_email_address answered ${answer:-nothing}" ;;
esac
rm -f "$jar" "$page"

echo "logs (last $SINCE)"
# Loki's HTTP API with curl: logcli can be denied local network access by macOS
loki_login=$(cat "$LOKI_CREDENTIALS" 2>/dev/null) || fail "no Loki login in $LOKI_CREDENTIALS (user:password)"
start=$(( ($(date +%s) - since_s) * 1000000000 ))
for stream in '{job="syslog", app=~"app-.+"}' '{namespace="'"$NAMESPACE"'", container=~"nginx-.+|postgresql|redis|app-.+"}'; do
  [ -n "${loki_login:-}" ] || break
  if ! json=$(curl -sS --fail-with-body -m 20 -u "$loki_login" -G "$LOKI_ADDR/loki/api/v1/query_range" --data-urlencode "start=$start" --data-urlencode limit=20 \
      --data-urlencode "query=$stream |~ \`$ERRORS\` !~ \`$IGNORE\`" 2>&1); then
    fail "$stream: Loki unreachable ($json)"; continue
  fi
  hits=$(python3 -c '
import json, sys, datetime
d = json.load(sys.stdin)
if d.get("status") != "success": print("query failed:", d); sys.exit()
lines = sorted((int(ts), line) for r in d["data"]["result"] for ts, line in r["values"])
for ts, line in lines[-20:]:
    print(datetime.datetime.fromtimestamp(ts / 1e9).strftime("%H:%M:%S"), line)
' <<< "$json" 2>&1)
  if [ -z "$hits" ]; then ok "$stream"; else fail "$stream:"; sed 's/^/          /' <<< "$hits" | cut -c1-220; fi
done

echo
if [ $failed = 0 ]; then echo "deploy OK"; else echo "deploy has problems (see FAIL above)"; exit 1; fi
