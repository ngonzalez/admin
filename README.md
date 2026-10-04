# admin

<img src="http://bit.ly/44Ufu09" width="200" />

Kubernetes manifests and helm values for the demo-app cluster: the apps
(backend, showcase, stream, frontend) behind nginx, PostgreSQL, Redis, and
the monitoring (Prometheus, Grafana, Loki, Alloy).

The [ansible](https://github.com/ngonzalez/ansible) repository applies them:
it pulls this repository's `dev` branch onto the node, so push `dev` before
deploying a change made here.

`make help` lists the commands.

#### Requirements
- SSH as root to the node (`NODE=root@192.168.1.14`): every command runs
  `kubectl` there, in the `development` namespace (`NAMESPACE`)
- the [ansible](https://github.com/ngonzalez/ansible) repository checked out
  next to this one (`ANSIBLE_DIR=../ansible`), for the `ansible-*`, `setup`
  and `deploy` targets. Install Ansible with `make ansible-install`.
- for `make check`: `curl`, `python3`, and the Loki login in
  `~/.config/loki-credentials` (one line, `user:password`)

#### Layout
```
namespace/         the development namespace
deploy/            the app and nginx deployments, the kubernetes dashboard
service/           their services
statefulset/       PostgreSQL and Redis
storage/           persistent volumes (PostgreSQL, Loki)
service-account/   the dashboard's admin user
helm/              values of the helm charts (Prometheus and its exporters,
                   Grafana, Loki, Alloy, metrics-server)
check-deploy.sh    the checks make check runs
```

#### Look at the cluster
```shell
make services    # the deployments and statefulsets: the SERVICE names
make pods        # ready, restarts, age, IP
make events      # the last events: scheduling, probes, restarts (TAIL=200)
```

#### Read the logs
`make logs` reads a service's logs with `kubectl logs`, from every container
of the deployment or statefulset, each line prefixed with its pod and
container and timestamped. It streams new lines until Ctrl-C.
```shell
make logs SERVICE=app-backend                     # the last 10 minutes, then live
make logs SERVICE=postgresql SINCE=1h FOLLOW=     # the last hour, then stop
make logs SERVICE=nginx-stream FILTER='error|crit'
make logs SERVICE=redis TAIL=50                   # at most 50 lines per container
```

| Variable  | Default | Meaning |
|-----------|---------|---------|
| `SERVICE` |         | required: a name from `make services` |
| `SINCE`   | `10m`   | how far back to start: `30s`, `10m`, `2h` |
| `TAIL`    | `200`   | at most this many lines per container (also for `make events`) |
| `FOLLOW`  | `true`  | stream new lines; `FOLLOW=` prints and stops |
| `FILTER`  |         | keep the lines matching this regexp, case-insensitive |

These logs come from the running pods only: a restarted pod's earlier logs
are gone. The app repositories' `make logs` reads Loki instead, which keeps
them (`SINCE=2d` works there).

#### Check a deploy
`make check` runs `check-deploy.sh`: every rollout finished, every pod ready
and none restarted, the public HTTPS endpoints answer 200, and Loki has no
errors from the apps, nginx, PostgreSQL or Redis. `SINCE` sets how far back
it looks for restarts and errors.
```shell
make check
make check SINCE=1h
```

#### Deploy
`make deploy` runs ansible's `deploy.yml`. Without TAGS it deploys
everything; TAGS limits it to some services (`make ansible-tags` lists them).
The app images are built by GitLab CI when the app's `dev` branch is pushed
(`:latest`); deploying an app recreates its pods, which pull the new image.
```shell
make ansible-tags                          # the TAGS setup and deploy accept
make deploy TAGS=app-backend,nginx-backend
make deploy                                # everything
make check
```
The Loki gateway's login is not stored in ansible: after a cluster rebuild,
recreate the `loki-gateway-auth` secret first (see ansible's
`roles/admin/tasks/main.yaml`), or the deploy stops at that check.

#### Set up the node
`make setup` runs ansible's `setup.yml`, role by role. Without TAGS it runs
every role, including the kube role, which **resets the cluster** with
`kubeadm reset -f` and builds a new one: run `make deploy` afterwards.
```shell
make ansible-ping                  # ansible reaches the node
make ansible-dry-run TAGS=firewall # --check --diff: what would change
make setup TAGS=firewall           # only these roles
make setup TAGS=helm               # update helm, without the cluster reset
make setup                         # every role: rebuilds the cluster
```

#### Test the ansible repository
```shell
make ansible-test    # syntax, ansible-lint, ansible's tests/*.yml
```
Its tests check, among others, that every manifest and helm values file here
is deployed by the admin role: remove a file, or deploy it, but don't leave
it unused.
