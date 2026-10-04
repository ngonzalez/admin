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
CONFIRM ?=

KUBECTL = ssh $(NODE) kubectl -n $(NAMESPACE)

.DEFAULT_GOAL := help

help: ## List the targets
	@echo "admin: make <target> [VAR=value]"
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t/' | expand -t 16 | sed 's/^/  /'
	@echo "  setup, deploy: TAGS=<tags from make ansible-tags, comma-separated> or TAGS=all"
	@echo "  ansible-dry-run: TAGS=<setup tags, e.g. firewall>"
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

ansible-install: ## Install ansible and ansible-lint (ansible/requirements.txt) with pyenv
	@cd $(ANSIBLE_DIR) && pyenv install -s $$(cat .python-version) && python -m pip install -q -r requirements.txt && ansible --version | head -1
.PHONY: ansible-install

ansible-ping: ## Check that ansible reaches the node
	@cd $(ANSIBLE_DIR) && ansible -i inventory.yaml all -m ping
.PHONY: ansible-ping

ansible-facts: ## Show the facts ansible gathers on the node
	@cd $(ANSIBLE_DIR) && ansible -i inventory.yaml all -m ansible.builtin.setup
.PHONY: ansible-facts

ansible-tags: ## List the TAGS that setup and deploy accept
	@cd $(ANSIBLE_DIR) && for p in setup deploy; do \
		printf '%-8s' "$$p:"; ansible-playbook -i inventory.yaml $$p.yml --list-tags 2>/dev/null | sed -n 's/.*TASK TAGS: \[\(.*\)\]/\1/p' | tr -d ' ' | tr ',' '\n' | grep -vxE 'always|never' | paste -sd' ' -; done
.PHONY: ansible-tags

# The kube role runs `kubeadm reset -f` before `kubeadm init`: it rebuilds the cluster
setup: ## Configure the node with ansible's setup.yml (TAGS required)
	@[ -n "$(TAGS)" ] || { echo "TAGS is required (TAGS=all runs every role):"; $(MAKE) -s ansible-tags | grep '^setup'; exit 1; }
	@case ",$(TAGS)," in *,all,*|*,kubernetes,*) [ "$(CONFIRM)" = 1 ] || { echo "TAGS=$(TAGS) runs the kube role, which resets the cluster (kubeadm reset -f) and builds a new one: add CONFIRM=1 to go ahead"; exit 1; };; esac
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.yaml setup.yml --diff $(if $(filter all,$(TAGS)),,--tags $(TAGS))
.PHONY: setup

deploy: ## Deploy to the cluster with ansible's deploy.yml (TAGS required)
	@[ -n "$(TAGS)" ] || { echo "TAGS is required (TAGS=all deploys everything):"; $(MAKE) -s ansible-tags | grep '^deploy'; exit 1; }
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.yaml deploy.yml --diff $(if $(filter all,$(TAGS)),,--tags $(TAGS))
.PHONY: deploy
