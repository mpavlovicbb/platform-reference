#!/usr/bin/env bash
# Serve the current checkout as a git repository the in-cluster ArgoCD can
# reach, so the e2e boots THIS revision's manifests — not upstream main.
# Mechanism: rewrite every repo URL to a container on the kind docker
# network, commit locally, and serve a bare clone over dumb HTTP (nginx).
# Also the documented pattern for booting a fork: see README quickstart.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPSTREAM_URL="https://github.com/mpavlovicbb/platform-reference"
SERVER_NAME="e2e-git"
NGINX_IMAGE="nginx:1.27-alpine"
SERVE_DIR="$(mktemp -d)"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v docker >/dev/null || fail "docker required"
docker network create kind >/dev/null 2>&1 || true

docker rm -f "$SERVER_NAME" >/dev/null 2>&1 || true
docker run -d --name "$SERVER_NAME" --network kind \
  -v "$SERVE_DIR":/usr/share/nginx/html:ro "$NGINX_IMAGE" >/dev/null
SERVER_IP="$(docker inspect -f '{{(index .NetworkSettings.Networks "kind").IPAddress}}' "$SERVER_NAME")"
[ -n "$SERVER_IP" ] || fail "could not determine $SERVER_NAME IP on the kind network"
LOCAL_URL="http://${SERVER_IP}/platform-reference.git"

cd "$REPO_ROOT"
echo "rewriting ${UPSTREAM_URL} -> ${LOCAL_URL}"
grep -rl --include='*.yaml' "$UPSTREAM_URL" bootstrap/ platform/ demo/ | while read -r f; do
  sed -i.bak "s|${UPSTREAM_URL}|${LOCAL_URL}|g" "$f" && rm -f "${f}.bak"
done

git config user.email "e2e@local" && git config user.name "e2e"
git add -A
git commit -q -m "e2e: point manifests at the local git server" --no-verify
# Bare-clone HEAD as main so every 'targetRevision: main' resolves here.
git checkout -q -B main
git clone -q --bare . "$SERVE_DIR/platform-reference.git"
git -C "$SERVE_DIR/platform-reference.git" update-server-info
chmod -R a+rX "$SERVE_DIR"

echo "serving $(git rev-parse --short HEAD) at ${LOCAL_URL}"
