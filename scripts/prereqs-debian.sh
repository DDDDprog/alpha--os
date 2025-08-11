#!/usr/bin/env bash
# Install prerequisites for native builds on Debian/Ubuntu
# Usage: sudo bash scripts/prereqs-debian.sh
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo bash scripts/prereqs-debian.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  live-build debootstrap xorriso squashfs-tools syslinux-efi \
  grub-pc-bin grub-efi-amd64-bin ca-certificates locales dosfstools mtools

echo "[✔] Prerequisites installed."
