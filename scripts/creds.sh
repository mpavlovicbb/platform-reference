#!/usr/bin/env bash
# Print service credentials for the running platform, on demand.
set -euo pipefail

KUBE_CONTEXT="kind-platform"
kc() { kubectl --context "$KUBE_CONTEXT" "$@"; }

kc cluster-info >/dev/null 2>&1 || { echo "cluster not reachable — run 'make up'" >&2; exit 1; }

argocd_pw="$(kc -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null \
  || echo "(initial secret deleted — use your changed password)")"
grafana_pw="$(kc -n monitoring get secret grafana-admin \
  -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d 2>/dev/null || echo "n/a")"

cat <<EOF
ArgoCD   http://localhost:8081                    admin / ${argocd_pw}
Grafana  http://grafana.platform.local:8080       admin / ${grafana_pw}
EOF
