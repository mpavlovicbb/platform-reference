#!/usr/bin/env bash
# Re-vendor the ArgoCD install manifest (issue #9): boot must not depend on
# a mutable git tag resolving over the network at cluster-admin privilege.
# Usage: scripts/vendor-argocd.sh v3.4.5
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:?usage: vendor-argocd.sh <version, e.g. v3.4.5>}"
DEST="$REPO_ROOT/bootstrap/argocd/argocd-install.yaml"

url="https://raw.githubusercontent.com/argoproj/argo-cd/${VERSION}/manifests/install.yaml"
tmp="$(mktemp)"
curl -fsSL "$url" -o "$tmp"
{
  echo "# Vendored ArgoCD install manifest — ${VERSION}"
  echo "# Source: ${url}"
  echo "# Re-vendor with: scripts/vendor-argocd.sh <version>"
  cat "$tmp"
} > "$DEST"
rm -f "$tmp"
echo "vendored ${VERSION} to bootstrap/argocd/argocd-install.yaml ($(du -h "$DEST" | cut -f1))"
