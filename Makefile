# Read the cluster's logs and state: kubectl on the node, over ssh.
# e.g. make logs SERVICE=postgresql SINCE=1h FILTER='ERROR|FATAL'

NODE ?= root@192.168.1.14
NAMESPACE ?= development
SERVICE ?=
SINCE ?= 10m
TAIL ?= 200
FILTER ?=
FOLLOW ?=
ANSIBLE_DIR ?= ../ansible
TAGS ?=

KUBECTL = ssh $(NODE) kubectl -n $(NAMESPACE)

.DEFAULT_GOAL := help

help: ## List the targets
	@echo "admin: make <target> [VAR=value]"
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t/' | expand -t 17 | sed 's/^/  /'
	@echo "  ansible-dry-run: TAGS=<role tags, e.g. firewall>"
	@echo "  logs: SERVICE=<name from make services> SINCE=$(SINCE) TAIL=$(TAIL) FOLLOW=1 FILTER=regexp"
.PHONY: help

services: ## List the deployments and statefulsets (the SERVICE names)
	@$(KUBECTL) get deploy,sts -o name | sed -E 's|^[a-z.]+/||' | sort
.PHONY: services

logs: ## Read a service's logs (all its containers; FOLLOW=1 to stream)
	@[ -n "$(SERVICE)" ] || { echo "SERVICE is required, one of:"; $(MAKE) -s services | sed 's/^/  /'; exit 1; }
	@ssh $(NODE) 'r=$$(kubectl -n $(NAMESPACE) get deploy,sts -o name | grep -E "^[a-z.]+/$(SERVICE)$$"); \
		[ -n "$$r" ] || { echo "no deployment or statefulset named $(SERVICE)"; exit 1; }; \
		kubectl -n $(NAMESPACE) logs "$$r" --all-containers --prefix --timestamps --since=$(SINCE) --tail=$(TAIL) $(if $(FOLLOW),--follow)' \
		$(if $(FILTER),| { grep -E --line-buffered '$(FILTER)' || true; })
.PHONY: logs

pods: ## Show the pods: ready, restarts, age
	@$(KUBECTL) get pods -o wide
.PHONY: pods

events: ## Show the recent events (scheduling, probes, restarts)
	@$(KUBECTL) get events --sort-by=.lastTimestamp | tail -n $(TAIL)
.PHONY: events

check: ## Check the last deploy: rollouts, pods, endpoints, log errors (SINCE)
	@./check-deploy.sh $(SINCE)
.PHONY: check

ansible-test: ## Test the ansible repo: syntax, lint, role tests (no node needed)
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.yaml setup.yml deploy.yml --syntax-check
	@cd $(ANSIBLE_DIR) && ansible-lint
	@cd $(ANSIBLE_DIR) && for t in tests/*.yml; do ansible-playbook "$$t" || exit 1; done
.PHONY: ansible-test

ansible-dry-run: ## Show what setup.yml would change on the node (--check --diff)
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.yaml setup.yml --check --diff $(if $(TAGS),--tags $(TAGS))
.PHONY: ansible-dry-run
