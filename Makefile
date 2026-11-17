# Run `make help` for the list of targets.
REGION       ?= us-east-1
STATE_BUCKET  = $(shell terraform -chdir=bootstrap output -raw state_bucket 2>/dev/null)
ANSIBLE       = cd ansible &&

.DEFAULT_GOAL := help
.PHONY: help bootstrap init plan apply inventory ping scan-before harden harden-check scan-after score lint destroy

help: ## Show this help
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-13s %s\n", $$1, $$2}'

bootstrap: ## One time: create the state bucket and the GitHub OIDC roles
	terraform -chdir=bootstrap init
	terraform -chdir=bootstrap apply

init: ## Point the fleet stack at the state bucket
	terraform -chdir=terraform init -backend-config="bucket=$(STATE_BUCKET)" -backend-config="region=$(REGION)"

plan: ## Show what Terraform would change
	terraform -chdir=terraform plan

apply: ## Build the network and the servers
	terraform -chdir=terraform apply

inventory: ## Show the servers Ansible found by tag
	$(ANSIBLE) ansible-galaxy collection install -r requirements.yml >/dev/null && ansible-inventory --graph

ping: ## Check SSH and sudo on every server
	$(ANSIBLE) ansible fleet -m ansible.builtin.ping

scan-before: ## OpenSCAP scan of the stock image
	$(ANSIBLE) ansible-playbook scan.yml -e scan_label=before

harden: ## Apply the base, hardening and audit roles, then reboot
	$(ANSIBLE) ansible-playbook site.yml

harden-check: ## Second run without the reboot: should report few or no changes
	$(ANSIBLE) ansible-playbook site.yml --skip-tags reboot

scan-after: ## OpenSCAP scan of the hardened servers
	$(ANSIBLE) ansible-playbook scan.yml -e scan_label=after

score: ## Print the before/after table for the README
	python3 scripts/score_table.py reports

lint: ## Run the same checks as CI
	terraform fmt -check -recursive
	terraform -chdir=terraform test
	yamllint .
	$(ANSIBLE) ansible-lint
	pytest -q

destroy: ## Delete the servers and the network (stops the charges)
	terraform -chdir=terraform destroy
