#!/usr/bin/env bash
set -euo pipefail

for dir in */; do
  pushd "$dir" >/dev/null
  docker compose up -d
  popd >/dev/null
done
