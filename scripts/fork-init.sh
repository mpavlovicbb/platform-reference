#!/usr/bin/env bash
# Point every manifest at YOUR fork (issue #11). Without this, a fork's
# `make up` deploys the upstream repository's main — ArgoCD pulls from the
# URLs written in the manifests, not from your checkout.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="https://github.com/mpavlovicbb/platform-reference"

cd "$REPO_ROOT"
origin="$(git remote get-url origin 2>/dev/null)" || { echo "no origin remote" >&2; exit 1; }
# Normalize git@github.com:user/repo(.git) to https form.
origin="${origin%.git}"
origin="${origin/#git@github.com:/https:\/\/github.com\/}"

if [ "$origin" = "$CANONICAL" ]; then
  echo "origin already is the canonical repository; nothing to do"
  exit 0
fi

echo "rewriting ${CANONICAL} -> ${origin}"
grep -rl --include='*.yaml' "$CANONICAL" bootstrap/ platform/ demo/ | while read -r f; do
  sed -i.bak "s|${CANONICAL}|${origin}|g" "$f" && rm -f "${f}.bak"
done

git add -A
git commit -m "chore: point manifests at this fork (fork-init)"
echo "done — push to your fork's main, then make up boots YOUR repository"
