SHELL := /bin/bash

.PHONY: venv prepare image pack infra deploy all nuke

ENV_FILE ?= .env.ctf
VENV_DIR ?= scripts/.venv
VENV_PYTHON := $(VENV_DIR)/bin/python
VENV_PIP := $(VENV_DIR)/bin/pip
PACKER_DIR ?= images
PACKER_TEMPLATE ?= image.pkr.hcl
AMI_FILE ?= .ami
TF_AMI_VARS_FILE ?= terraform/ami.auto.tfvars

venv:
	@test -x "$(VENV_PYTHON)" || python3 -m venv "$(VENV_DIR)"
	@"$(VENV_PIP)" install -r scripts/requirements.txt

prepare: venv
	@test -f "$(ENV_FILE)" || (echo "Missing config file: $(ENV_FILE)" >&2; exit 1)
	@bash scripts/move_chall.sh "$(ENV_FILE)"
	@teams="$$(awk -F= '/^[[:space:]]*TEAMS[[:space:]]*=/{gsub(/[[:space:]]/, "", $$2); print $$2; exit}' "$(ENV_FILE)")"; \
	players="$$(awk -F= '/^[[:space:]]*(PLAYER_PER_TEAMS|PLAYERS_PER_TEAM)[[:space:]]*=/{gsub(/[[:space:]]/, "", $$2); print $$2; exit}' "$(ENV_FILE)")"; \
	test -n "$$teams" || (echo "TEAMS missing in $(ENV_FILE)" >&2; exit 1); \
	test -n "$$players" || (echo "PLAYER_PER_TEAMS (or PLAYERS_PER_TEAM) missing in $(ENV_FILE)" >&2; exit 1); \
	"$(VENV_PYTHON)" scripts/gen.py --teams "$$teams" --players-per-team "$$players"

image:
	@test -n "$${AWS_ACCESS_KEY_ID:-}" || (echo "AWS_ACCESS_KEY_ID is required" >&2; exit 1)
	@test -n "$${AWS_SECRET_ACCESS_KEY:-}" || (echo "AWS_SECRET_ACCESS_KEY is required" >&2; exit 1)
	@test -f "$(PACKER_DIR)/$(PACKER_TEMPLATE)" || (echo "Missing $(PACKER_DIR)/$(PACKER_TEMPLATE)" >&2; exit 1)
	@region="$${AWS_REGION:-eu-west-1}"; \
	tmp_log="$$(mktemp)"; \
	(cd "$(PACKER_DIR)" && packer init "$(PACKER_TEMPLATE)"); \
	set -o pipefail; \
	(cd "$(PACKER_DIR)" && packer build -var "region=$$region" -machine-readable "$(PACKER_TEMPLATE)") 2>&1 | tee "$$tmp_log"; \
	status="$${PIPESTATUS[0]}"; \
	if [ "$$status" -ne 0 ]; then \
	  rm -f "$$tmp_log"; \
	  exit "$$status"; \
	fi; \
	ami="$$(awk -F, '/,artifact,[0-9]+,id,/ {print $$NF}' "$$tmp_log" | tail -n1)"; \
	ami="$${ami##*:}"; \
	rm -f "$$tmp_log"; \
	test -n "$$ami" || (echo "Failed to parse AMI ID from Packer output" >&2; exit 1); \
	printf '%s\n' "$$ami" > "$(AMI_FILE)"; \
	printf 'ami_id = "%s"\naws_region = "%s"\n' "$$ami" "$$region" > "$(TF_AMI_VARS_FILE)"; \
	echo "AMI saved to $(AMI_FILE) and $(TF_AMI_VARS_FILE): $$ami"

pack:
	@cp -r deploy/teams .teams
	@sed -i -e "s/@@CHANGEME@@/$$(tofu -chdir=terraform/ output -json | jq -r '.gameserver_ip.value')/g" .teams/**/*.conf

	@mkdir -p output

	@for d in .teams/*/ ; do \
      zip -j -r "output/$$(basename $$d).zip" "$$d"/* ; \
	done

	@rm -r .teams

infra:
	@tofu -chdir=terraform/ init
	@tofu -chdir=terraform/ apply
	

deploy:
	@env ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ansible/playbook.yml -i ./deploy/inventory.ini -u ubuntu

all: prepare image infra deploy pack

nuke:
	@tofu -chdir=terraform/ destroy
	@rm -rf output/
