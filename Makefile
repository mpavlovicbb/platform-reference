# Platform reference — entrypoints.
# Targets marked with ## are self-documenting; `make` lists them.

.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

.PHONY: help up down status creds seed lint cast

help: ## List available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Boot the full platform in kind (preflight, cluster, ArgoCD, all apps healthy)
	@./scripts/up.sh

down: ## Tear everything down, leaving no containers behind
	@./scripts/down.sh

status: ## Show sync and health state of every application
	@./scripts/status.sh

creds: ## Print service credentials for the running platform
	@./scripts/creds.sh

seed: ## Deploy demo workloads and traffic so dashboards show real curves
	@./scripts/seed.sh

lint: ## Run every check CI runs, locally
	@pre-commit run --all-files

cast: ## Record the README tour GIF (needs a running cluster)
	@./scripts/record-cast.sh
