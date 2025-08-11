#!/usr/bin/env bash
# Quick diagnostics for live-build env
set -euo pipefail
echo "lb version:"
lb --version || true
echo
echo "live-build config variables:"
set | grep -E '^LB_' || true
echo
echo "Auto config file:"
sed -n '1,200p' live-build/auto/config || true
