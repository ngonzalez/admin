#!/usr/bin/env bash
# Checks that a deploy of the demo-app org projects succeeded:
#   1. every deployment / statefulset in the namespace finished its rollout
#   2. every pod is ready and none restarted since the deploy
#   3. the public HTTPS endpoints answer 200 with a valid certificate
#   4. no errors in the app, nginx, PostgreSQL and Redis logs since the deploy
#
# usage: ./check-deploy.sh [SINCE]   (default 10m: how far back to look for restarts and errors)
# needs: ssh access to the node, curl, python3
set -uo pipefail

SINCE=${1:-10m}
NODE=${NODE:-root@192.168.1.14}
NAMESPACE=${NAMESPACE:-development}
DOMAIN=${DOMAIN:-link12.ddns.net}
LOKI_ADDR=${LOKI_ADDR:-http://192.168.1.14:3100}
# frontend, backend, stream, showcase
ENDPOINTS=(443 4040/_health 5050 6060)
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
        if last and (now - datetime.datetime.fromisoformat(last["finishedAt"].replace("Z", "+00:00"))).total_seconds() < since:
            problems.append(cname + " restarted (" + str(last.get("reason")) + ")")
    print(("FAIL " + name + ": " + ", ".join(problems)) if problems else ("ok " + name))
' "$since_s" > /tmp/check-deploy-pods.$$
while read -r status rest; do
  if [ "$status" = ok ]; then ok "$rest"; else fail "$rest"; fi
done < /tmp/check-deploy-pods.$$
rm -f /tmp/check-deploy-pods.$$

echo "endpoints"
for e in "${ENDPOINTS[@]}"; do
  url="https://$DOMAIN:${e%%/*}/${e#*/}"; [ "${e#*/}" = "$e" ] && url="https://$DOMAIN:$e/"
  read -r code verify <<< "$(curl -s -o /dev/null -m 10 -w '%{http_code} %{ssl_verify_result}' "$url")"
  if [ "$code" = 200 ] && [ "$verify" = 0 ]; then ok "$url"; else fail "$url: HTTP $code, certificate check $verify"; fi
done

echo "logs (last $SINCE)"
# Loki's HTTP API with curl: logcli can be denied local network access by macOS
start=$(( ($(date +%s) - since_s) * 1000000000 ))
for stream in '{job="syslog", app=~"app-.+"}' '{namespace="'"$NAMESPACE"'", container=~"nginx-.+|postgresql|redis|app-.+"}'; do
  if ! json=$(curl -sS -m 20 -G "$LOKI_ADDR/loki/api/v1/query_range" --data-urlencode "start=$start" --data-urlencode limit=20 \
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
