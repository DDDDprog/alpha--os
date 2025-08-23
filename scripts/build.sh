#!/usr/bin/env bash
# Build Alpha OS ISO natively on Debian/Ubuntu
# Usage: sudo bash scripts/build.sh
set -euo pipefail
[[ "${DEBUG:-0}" = "1" ]] && set -x

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo bash scripts/build.sh"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LB_DIR="${ROOT_DIR}/live-build"
OUT_DIR="${ROOT_DIR}/out"
LOG_FILE="${OUT_DIR}/build.log"

mkdir -p "${OUT_DIR}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1. Run: sudo bash scripts/prereqs-debian.sh"; exit 1; }; }
need lb
need debootstrap
need xorriso
need mksquashfs

chmod +x "${LB_DIR}/auto/config" || true
find "${LB_DIR}/config/hooks" -type f -name "*.chroot" -exec chmod +x {} \; || true
chmod +x "${LB_DIR}/config/includes.chroot/usr/local/bin/alpha-welcome" || true

cd "${LB_DIR}"

echo "[*] Cleaning any previous build (purge)..." | tee "${LOG_FILE}"
lb clean --purge || true |& tee -a "${LOG_FILE}"

echo "[*] Configuring live-build..." | tee -a "${LOG_FILE}"
set +e

lb config noauto \
  --distribution bookworm \
  --architectures amd64 \
  --archive-areas main contrib non-free non-free-firmware \
  --mirror-bootstrap http://deb.debian.org/debian/ \
  --mirror-chroot http://deb.debian.org/debian/ \
  --mirror-chroot-security http://security.debian.org/debian-security \
  --mirror-binary http://deb.debian.org/debian/ \
  --binary-images iso-hybrid \
  --debian-installer none \
  --apt-recommends false \
  --bootappend-live "persistence locales=en_US.UTF-8 timezone=UTC keyboard-layouts=us" \
  --initramfs live-boot |& tee -a "${LOG_FILE}"

CFG_STATUS=${PIPESTATUS[0]}
set -e
if [[ ${CFG_STATUS} -ne 0 ]]; then
  echo "[!] lb config failed, see ${LOG_FILE}" | tee -a "${LOG_FILE}"
  exit ${CFG_STATUS}
fi

echo "[*] Building ISO (this can take a while)..." | tee -a "${LOG_FILE}"
set +e
lb build |& tee -a "${LOG_FILE}"
BUILD_STATUS=${PIPESTATUS[0]}
set -e
if [[ ${BUILD_STATUS} -ne 0 ]]; then
  echo "[!] lb build failed, see ${LOG_FILE}. Tail:" | tee -a "${LOG_FILE}"
  tail -n 120 "${LOG_FILE}" || true
  exit ${BUILD_STATUS}
fi

echo "[*] Handling output ISO(s)..." | tee -a "${LOG_FILE}"
shopt -s nullglob
ISOS=( ./*.iso )
if (( ${#ISOS[@]} == 0 )); then
  echo "No ISO produced. Check ${LOG_FILE} for errors." | tee -a "${LOG_FILE}"
  exit 1
fi

mkdir -p "${OUT_DIR}"
for iso in "${ISOS[@]}"; do
  cp -v "$iso" "${OUT_DIR}/" | tee -a "${LOG_FILE}"
done

CANON="${OUT_DIR}/alpha-os-bookworm-amd64.iso"
cp -v "${ISOS[0]}" "$CANON" | tee -a "${LOG_FILE}" || true

echo "[✔] Done. ISO(s) available in: ${OUT_DIR}" | tee -a "${LOG_FILE}"
echo "    Canonical: $CANON" | tee -a "${LOG_FILE}"
