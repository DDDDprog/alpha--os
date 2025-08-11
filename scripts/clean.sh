#!/usr/bin/env bash
# Deep clean all build artifacts
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}/live-build"
sudo lb clean --purge || true
sudo rm -rf cache chroot binary build.log *.iso 2>/dev/null || true
echo "[✔] Clean complete."
