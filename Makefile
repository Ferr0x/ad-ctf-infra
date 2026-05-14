.PHONY: venv prepare pack infra deploy all nuke

ENV_FILE ?= .env.ctf
VENV_DIR ?= scripts/.venv
VENV_PYTHON := $(VENV_DIR)/bin/python
VENV_PIP := $(VENV_DIR)/bin/pip

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

all: prepare infra deploy pack

nuke:
	@tofu -chdir=terraform/ destroy
	@rm -rf output/

