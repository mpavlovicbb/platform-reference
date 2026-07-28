#!/usr/bin/env bash
# Records the README hero cast: a scripted tour of a running platform.
# Requires a booted cluster (make up) plus asciinema and agg.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAST="$REPO_ROOT/docs/assets/tour.cast"
GIF="$REPO_ROOT/docs/assets/tour.gif"

command -v asciinema >/dev/null || { echo "asciinema not installed" >&2; exit 1; }
command -v agg >/dev/null || { echo "agg not installed" >&2; exit 1; }
kubectl cluster-info --context kind-platform >/dev/null 2>&1 \
  || { echo "cluster not running - make up first" >&2; exit 1; }

rm -f "$CAST"
asciinema rec "$CAST" --cols 100 --rows 30 --command "$REPO_ROOT/scripts/cast-tour.sh"
agg --font-size 16 --speed 1.4 "$CAST" "$GIF"
rm -f "$CAST"
echo "wrote $GIF ($(du -h "$GIF" | cut -f1))"
