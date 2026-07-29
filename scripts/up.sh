#!/usr/bin/env bash
# Boot the full platform from nothing: kind cluster, local registry, ArgoCD,
# and every application under platform/. Idempotent: safe to re-run at any point.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGOCD_VERSION="v3.4.5"
CLUSTER_NAME="platform"
KUBE_CONTEXT="kind-${CLUSTER_NAME}"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"
APP_WAIT_TIMEOUT_SECONDS=600

# Every kubectl call is pinned to the kind context: a re-run must never touch
# whatever cluster the user's current context happens to point at.
kc() { kubectl --context "$KUBE_CONTEXT" "$@"; }

say()  { printf '\n==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- Preflight -------------------------------------------------------------
say "Preflight checks"
for tool in docker kind kubectl helm jq; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is required but not installed"
done
docker info >/dev/null 2>&1 || fail "Docker daemon is not running. Start Docker and re-run."

# This measures the memory allocated to the Docker VM/daemon, not free memory.
# Threshold sits below 8 GiB because Docker Desktop reserves some of the
# configured allocation for the VM kernel — a slider set to exactly 8 GB
# reports slightly less and should still pass.
docker_mem_bytes="$(docker info --format '{{.MemTotal}}' 2>/dev/null || true)"
[[ "$docker_mem_bytes" =~ ^[0-9]+$ ]] || fail "could not read Docker memory allocation (docker info MemTotal)"
min_mem_bytes=$((7 * 1024 * 1024 * 1024))
if [ "$docker_mem_bytes" -lt "$min_mem_bytes" ]; then
  fail "Docker has $(awk "BEGIN {printf \"%.1f\", $docker_mem_bytes/1024/1024/1024}") GB allocated; at least ~7 GB (8 GB slider) is required"
fi
echo "docker, kind, kubectl, helm, jq present; Docker memory allocation OK"

start_time=$(date +%s)

# --- Local registry --------------------------------------------------------
say "Local registry"
if docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
  if [ "$(docker inspect -f '{{.State.Running}}' "$REGISTRY_NAME")" != "true" ]; then
    docker start "$REGISTRY_NAME" >/dev/null
    echo "restarted existing $REGISTRY_NAME"
  else
    echo "$REGISTRY_NAME already running"
  fi
else
  docker run -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" \
    --name "$REGISTRY_NAME" registry:2 >/dev/null
  echo "started $REGISTRY_NAME on localhost:${REGISTRY_PORT}"
fi

# --- Cluster ---------------------------------------------------------------
say "kind cluster"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "cluster '$CLUSTER_NAME' already exists"
else
  kind create cluster --config "$REPO_ROOT/bootstrap/kind/cluster.yaml" --wait 120s
fi
kc cluster-info >/dev/null 2>&1 || fail "context $KUBE_CONTEXT is not reachable"
docker network connect kind "$REGISTRY_NAME" 2>/dev/null || true

kc apply -f - <<EOF
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

# --- Runtime-generated credentials -----------------------------------------
# The Vault dev root token is generated here on every fresh cluster and lands
# only in in-cluster Secrets — never in git, never in a file. The secret must
# exist identically in both namespaces; partial state is repaired from the
# vault-namespace copy.
say "Vault dev token"
for ns in vault external-secrets; do
  kc create namespace "$ns" --dry-run=client -o yaml | kc apply -f - >/dev/null
done
if ! kc -n vault get secret vault-dev-token >/dev/null 2>&1; then
  vault_token="$(head -c 24 /dev/urandom | base64 | tr -d '/+=')"
  kc -n vault create secret generic vault-dev-token \
    --from-literal=token="$vault_token" >/dev/null
  unset vault_token
  echo "generated"
else
  echo "already present"
fi
if ! kc -n external-secrets get secret vault-dev-token >/dev/null 2>&1; then
  token_b64="$(kc -n vault get secret vault-dev-token -o jsonpath='{.data.token}')"
  kc -n external-secrets create secret generic vault-dev-token \
    --from-literal=token="$(echo "$token_b64" | base64 -d)" >/dev/null
  echo "replicated to external-secrets namespace"
fi

say "Grafana admin credentials"
kc create namespace monitoring --dry-run=client -o yaml | kc apply -f - >/dev/null
if ! kc -n monitoring get secret grafana-admin >/dev/null 2>&1; then
  kc -n monitoring create secret generic grafana-admin \
    --from-literal=admin-user=admin \
    --from-literal=admin-password="$(head -c 18 /dev/urandom | base64 | tr -d '/+=')" >/dev/null
  echo "generated"
else
  echo "already present"
fi

# --- ArgoCD ----------------------------------------------------------------
say "ArgoCD ${ARGOCD_VERSION}"
kc create namespace argocd --dry-run=client -o yaml | kc apply -f - >/dev/null
# Server-side apply: the ApplicationSet CRD exceeds the 256 KB annotation limit
# that client-side apply needs for last-applied-configuration.
kc apply --server-side --force-conflicts -n argocd \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

# Local-only: serve without TLS (see bootstrap/argocd/local-overrides.yaml).
# Restart the server only when the setting actually changed.
insecure_before="$(kc -n argocd get configmap argocd-cmd-params-cm \
  -o jsonpath='{.data.server\.insecure}' 2>/dev/null || true)"
kc -n argocd patch configmap argocd-cmd-params-cm \
  --type merge -p '{"data":{"server.insecure":"true"}}' >/dev/null
kc apply -f "$REPO_ROOT/bootstrap/argocd/local-overrides.yaml" >/dev/null

# Restore the Application health check ArgoCD removed in 1.8: without it,
# sync waves between child Applications are decorative and ordering degrades
# to retry-driven convergence.
kc -n argocd patch configmap argocd-cm --type merge -p '{
  "data": {
    "resource.customizations.health.argoproj.io_Application": "hs = {}\nhs.status = \"Progressing\"\nhs.message = \"\"\nif obj.status ~= nil then\n  if obj.status.health ~= nil then\n    hs.status = obj.status.health.status\n    if obj.status.health.message ~= nil then\n      hs.message = obj.status.health.message\n    end\n  end\nend\nreturn hs\n"
  }
}' >/dev/null

if [ "$insecure_before" != "true" ]; then
  kc -n argocd rollout restart deployment argocd-server
fi
kc -n argocd rollout restart statefulset argocd-application-controller >/dev/null 2>&1 || true

say "Waiting for ArgoCD to become available"
kc -n argocd rollout status deployment argocd-server --timeout=240s \
  || fail "argocd-server did not become available; run 'kubectl --context $KUBE_CONTEXT -n argocd get pods' to inspect"

# --- Root application ------------------------------------------------------
say "Root application"
kc apply -f "$REPO_ROOT/bootstrap/argocd/root-app.yaml" >/dev/null

say "Waiting for all applications to be Synced and Healthy (timeout ${APP_WAIT_TIMEOUT_SECONDS}s)"
deadline=$(($(date +%s) + APP_WAIT_TIMEOUT_SECONDS))
while true; do
  # A transient API hiccup must cost one iteration, not the whole boot.
  apps_json="$(kc get applications.argoproj.io -n argocd -o json 2>/dev/null || true)"
  if [ -n "$apps_json" ]; then
    total="$(echo "$apps_json" | jq '.items | length')"
    ready="$(echo "$apps_json" | jq '[.items[]
      | select(.status.sync.status == "Synced" and .status.health.status == "Healthy")]
      | length')"
    if [ "$total" -gt 0 ] && [ "$ready" -eq "$total" ]; then
      echo "all ${total} applications Synced and Healthy"
      break
    fi
    echo "  ${ready:-0}/${total:-?} ready..."
  else
    echo "  (api unavailable, retrying)"
  fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "--- current application state ---"
    kc get applications.argoproj.io -n argocd \
      -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status' || true
    fail "not all applications became Synced+Healthy within ${APP_WAIT_TIMEOUT_SECONDS}s"
  fi
  sleep 5
done

# --- Report ----------------------------------------------------------------
elapsed=$(($(date +%s) - start_time))
# The initial admin secret may have been deleted post-login, per ArgoCD's own
# recommendation; that must not fail an otherwise successful boot.
admin_password="$(kc -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null \
  || echo "(initial secret deleted — use your changed password)")"
grafana_password="$(kc -n monitoring get secret grafana-admin \
  -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d 2>/dev/null || echo "n/a")"

say "Platform is up (${elapsed}s)"
if [ -t 1 ]; then
  cat <<EOF

  Service    URL                                          Credentials
  -------    ---                                          -----------
  ArgoCD     http://localhost:8081                        admin / ${admin_password}
  Grafana    http://grafana.platform.local:8080 (*)       admin / ${grafana_password}
  podinfo    http://podinfo.platform.local:8080 (*)

  (*) Host-header routed through the gateway: either add the names to
      /etc/hosts as 127.0.0.1, or curl -H "Host: <name>" http://localhost:8080

Teardown with 'make down'. Application state: 'make status'. Credentials
again later: 'make creds'.
EOF
else
  # Non-interactive (CI, piped): never write credentials into logs.
  echo "Credentials withheld from non-interactive output; run 'make creds'."
fi
