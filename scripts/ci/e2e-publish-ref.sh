#!/usr/bin/env bash
# Make ArgoCD sync THIS revision instead of main: rewrite every tracked
# revision to a temporary ref, commit, and push that ref to the real repo.
# ArgoCD then fetches it over plain https — no local git server, because the
# repo-server's go-git ref listing cannot speak dumb HTTP.
#
# Requires push access (contents: write). Fork PRs run with a read-only
# token and cannot use this path — a documented limitation until a
# smart-HTTP local server replaces it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
E2E_REF="${E2E_REF:?E2E_REF is required, e.g. refs/e2e/12345}"

cd "$REPO_ROOT"
echo "rewriting tracked revision main -> ${E2E_REF}"
grep -rl --include='*.yaml' -E '(targetRevision|revision): main' bootstrap/ platform/ demo/ | while read -r f; do
  sed -i.bak -E "s|(targetRevision): main|\1: ${E2E_REF}|; s|(revision): main|\1: ${E2E_REF}|" "$f" && rm -f "${f}.bak"
done

git config user.email "e2e@local" && git config user.name "e2e"
git add -A
git commit -q -m "e2e: track ${E2E_REF}" --no-verify
git push -q origin "HEAD:${E2E_REF}"
echo "pushed $(git rev-parse --short HEAD) as ${E2E_REF}"
