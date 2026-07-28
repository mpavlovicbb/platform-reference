#!/usr/bin/env bash
# One-screen view of platform state: nodes and every ArgoCD application.
set -euo pipefail

if ! kubectl cluster-info --context kind-platform >/dev/null 2>&1; then
  echo "cluster 'kind-platform' is not reachable — run 'make up'" >&2
  exit 1
fi

echo "== Nodes =="
kubectl get nodes -o wide --no-headers | awk '{printf "  %-24s %-8s %s\n", $1, $2, $6}'

echo
echo "== Applications =="
kubectl get applications.argoproj.io -n argocd \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision' \
  | sed 's/^/  /'
