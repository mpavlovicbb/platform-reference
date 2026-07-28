#!/usr/bin/env bash
# Boot the full platform from nothing: kind cluster, local registry, ArgoCD,
# and every application under platform/. Idempotent: safe to re-run at any point.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGOCD_VERSION="v3.4.5"
CLUSTER_NAME="platform"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"
APP_WAIT_TIMEOUT_SECONDS=420

say()  { printf '\n==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- Preflight -------------------------------------------------------------
say "Preflight checks"
for tool in docker kind kubectl helm jq; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is required but not installed"
done
docker info >/dev/null 2>&1 || fail "Docker daemon is not running. Start Docker and re-run."

docker_mem_bytes="$(docker info --format '{{.MemTotal}}')"
min_mem_bytes=$((8 * 1024 * 1024 * 1024))
if [ "$docker_mem_bytes" -lt "$min_mem_bytes" ]; then
  fail "Docker has $((docker_mem_bytes / 1024 / 1024 / 1024)) GB RAM; at least 8 GB is required"
fi
echo "docker, kind, kubectl, helm, jq present; Docker RAM OK"

start_time=$(date +%s)

# --- Local registry --------------------------------------------------------
say "Local registry"
if [ "$(docker inspect -f '{{.State.Running}}' "$REGISTRY_NAME" 2>/dev/null || true)" != "true" ]; then
  docker run -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" \
    --name "$REGISTRY_NAME" registry:2 >/dev/null
  echo "started $REGISTRY_NAME on localhost:${REGISTRY_PORT}"
else
  echo "$REGISTRY_NAME already running"
fi

# --- Cluster ---------------------------------------------------------------
say "kind cluster"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "cluster '$CLUSTER_NAME' already exists"
else
  kind create cluster --config "$REPO_ROOT/bootstrap/kind/cluster.yaml" --wait 120s
fi
docker network connect kind "$REGISTRY_NAME" 2>/dev/null || true

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# --- ArgoCD ----------------------------------------------------------------
say "ArgoCD ${ARGOCD_VERSION}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# Server-side apply: the ApplicationSet CRD exceeds the 256 KB annotation limit
# that client-side apply needs for last-applied-configuration.
kubectl apply --server-side --force-conflicts -n argocd \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

# Local-only: serve without TLS (see bootstrap/argocd/local-overrides.yaml).
kubectl -n argocd patch configmap argocd-cmd-params-cm \
  --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl apply -f "$REPO_ROOT/bootstrap/argocd/local-overrides.yaml"
kubectl -n argocd rollout restart deployment argocd-server

say "Waiting for ArgoCD to become available"
kubectl -n argocd rollout status deployment argocd-server --timeout=240s \
  || fail "argocd-server did not become available; run 'kubectl -n argocd get pods' to inspect"

# --- Root application ------------------------------------------------------
say "Root application"
kubectl apply -f "$REPO_ROOT/bootstrap/argocd/root-app.yaml"

say "Waiting for all applications to be Synced and Healthy (timeout ${APP_WAIT_TIMEOUT_SECONDS}s)"
deadline=$(($(date +%s) + APP_WAIT_TIMEOUT_SECONDS))
while true; do
  apps_json="$(kubectl get applications.argoproj.io -n argocd -o json)"
  total="$(echo "$apps_json" | jq '.items | length')"
  ready="$(echo "$apps_json" | jq '[.items[]
    | select(.status.sync.status == "Synced" and .status.health.status == "Healthy")]
    | length')"
  if [ "$total" -gt 0 ] && [ "$ready" -eq "$total" ]; then
    echo "all ${total} applications Synced and Healthy"
    break
  fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "--- current application state ---"
    kubectl get applications.argoproj.io -n argocd \
      -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status'
    fail "not all applications became Synced+Healthy within ${APP_WAIT_TIMEOUT_SECONDS}s"
  fi
  echo "  ${ready}/${total} ready..."
  sleep 5
done

# --- Report ----------------------------------------------------------------
elapsed=$(($(date +%s) - start_time))
admin_password="$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)"

say "Platform is up (${elapsed}s)"
cat <<EOF

  Service    URL                     Credentials
  -------    ---                     -----------
  ArgoCD     http://localhost:8081   admin / ${admin_password}
  podinfo    kubectl -n demo port-forward svc/podinfo 9898:9898

Teardown with 'make down'. Application state: 'make status'.
EOF
