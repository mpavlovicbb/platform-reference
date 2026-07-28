#!/usr/bin/env bash
# Full teardown: cluster and registry. Leaves no containers behind.
set -euo pipefail

CLUSTER_NAME="platform"
REGISTRY_NAME="kind-registry"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "cluster '$CLUSTER_NAME' not present"
fi

if docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
  docker rm -f "$REGISTRY_NAME" >/dev/null
  echo "removed $REGISTRY_NAME"
else
  echo "registry '$REGISTRY_NAME' not present"
fi
