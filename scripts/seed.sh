#!/usr/bin/env bash
# Seed the running platform with demo signal: build the queue worker into the
# local registry, then deploy the seed Application (traffic generator + queue
# worker). Kept out of make up on purpose — boot must not depend on an image
# that only exists after this script builds it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBE_CONTEXT="kind-platform"
REGISTRY="localhost:5001"
IMAGE="queue-worker:0.1.0"
WAIT_TIMEOUT_SECONDS=300

kc() { kubectl --context "$KUBE_CONTEXT" "$@"; }
say()  { printf '\n==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

kc cluster-info >/dev/null 2>&1 || fail "cluster not reachable — run 'make up' first"
docker info >/dev/null 2>&1 || fail "Docker daemon is not running"

say "Building ${IMAGE} into the local registry"
docker build -q -t "${REGISTRY}/${IMAGE}" "$REPO_ROOT/demo/workloads/queue-worker" >/dev/null
docker push -q "${REGISTRY}/${IMAGE}" >/dev/null
echo "pushed ${REGISTRY}/${IMAGE}"

say "Deploying seed application"
kc apply -f "$REPO_ROOT/demo/seed/demo-seed-app.yaml" >/dev/null

say "Waiting for demo-seed to be Synced and Healthy (timeout ${WAIT_TIMEOUT_SECONDS}s)"
deadline=$(($(date +%s) + WAIT_TIMEOUT_SECONDS))
while true; do
  state="$(kc get application demo-seed -n argocd \
    -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null || true)"
  if [ "$state" = "Synced/Healthy" ]; then
    echo "demo-seed Synced and Healthy"
    break
  fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    kc get application demo-seed -n argocd \
      -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status' || true
    fail "demo-seed did not become healthy within ${WAIT_TIMEOUT_SECONDS}s"
  fi
  echo "  ${state:-pending}..."
  sleep 5
done

say "Seeded"
cat <<EOF
Traffic is flowing: healthy load on podinfo and the shop tenant, injected
faults on the flaky tenant, sawtooth queue depth from the worker. Dashboards
have curves within a couple of minutes:

  http://grafana.platform.local:8080  (make creds for the password)

Remove with: kubectl --context ${KUBE_CONTEXT} -n argocd delete application demo-seed
EOF
