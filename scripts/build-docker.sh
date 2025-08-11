#!/usr/bin/env bash
# Build Alpha OS live ISO using Docker
# Usage: bash scripts/build-docker.sh
set -euo pipefail

IMAGE_NAME="alpha-os-live"
OUT_DIR="$(pwd)/out"

mkdir -p "${OUT_DIR}"

echo "[*] Building container image..."
docker build -t "${IMAGE_NAME}" .

echo "[*] Running live-build in container (requires --privileged for loop devices)..."
docker run --rm --privileged \
  -v "$(pwd)/live-build:/workspace/live-build" \
  -v "${OUT_DIR}:/workspace/out" \
  "${IMAGE_NAME}" bash -lc 'lb clean --purge || true && lb config && lb build && cp -v *.iso /workspace/out/'

echo "[✔] Done. ISO(s) are in: ${OUT_DIR}"
