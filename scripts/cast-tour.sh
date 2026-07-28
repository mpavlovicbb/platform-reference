#!/usr/bin/env bash
# The scripted tour that record-cast.sh captures. Pacing tuned for a short GIF.
set -euo pipefail

type_cmd() {
  printf '$ '
  for ((i = 0; i < ${#1}; i++)); do printf '%s' "${1:i:1}"; sleep 0.02; done
  printf '\n'
  sleep 0.3
}

type_cmd "make status   # one GitOps root, every component reconciled"
./scripts/status.sh
sleep 2.5

type_cmd "kubectl run bad --image=nginx:latest -n demo   # policy says no"
kubectl run bad --image=nginx:latest -n demo 2>&1 | head -8 || true
sleep 2.5

type_cmd "curl -H 'Host: podinfo.platform.local' localhost:8080   # through Envoy Gateway"
curl -s -H "Host: podinfo.platform.local" http://localhost:8080/ | head -12
sleep 2.5

type_cmd "kubectl -n demo get secret demo-config   # Vault -> ExternalSecret -> Secret"
kubectl -n demo get secret demo-config
sleep 3
