#!/usr/bin/env bash
# One-screen view of platform state: nodes and every ArgoCD application.
# Pinned to the kind context: never reads whatever cluster the user's current
# context points at.
set -euo pipefail

KUBE_CONTEXT="kind-platform"
kc() { kubectl --context "$KUBE_CONTEXT" "$@"; }

if ! kc cluster-info >/dev/null 2>&1; then
  echo "cluster '$KUBE_CONTEXT' is not reachable — run 'make up'" >&2
  exit 1
fi

echo "== Nodes =="
kc get nodes -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[-1].type,IP:.status.addresses[0].address' --no-headers | sed 's/^/  /'

echo
echo "== Applications =="
kc get applications.argoproj.io -n argocd \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision' \
  | sed 's/^/  /'
