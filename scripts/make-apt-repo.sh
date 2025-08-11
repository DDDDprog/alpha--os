#!/usr/bin/env bash
# Create a simple local APT repo from a folder of .deb packages
# Usage: ./scripts/make-apt-repo.sh /path/to/debs /tmp/alpha-repo
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <deb-dir> <repo-dir>"
  exit 1
fi

DEB_DIR="$1"
REPO_DIR="$2"

mkdir -p "$REPO_DIR/dists/bookworm/main/binary-amd64"
mkdir -p "$REPO_DIR/pool/main/a/alpha-os"

# Copy debs into pool
find "$DEB_DIR" -type f -name "*.deb" -exec cp -v {} "$REPO_DIR/pool/main/a/alpha-os/" \;

# Generate Packages and Release files (requires dpkg-dev and apt-utils)
if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
  echo "Installing dpkg-dev..."
  sudo apt-get update && sudo apt-get install -y dpkg-dev apt-utils
fi

cd "$REPO_DIR"
dpkg-scanpackages --arch amd64 pool/main/a/alpha-os > dists/bookworm/main/binary-amd64/Packages
gzip -fk dists/bookworm/main/binary-amd64/Packages

cat > dists/bookworm/Release <<EOF
Codename: bookworm
Components: main
Architectures: amd64
EOF

echo "[✔] Repo built at: $REPO_DIR"
echo "You can serve it with: python3 -m http.server -d $REPO_DIR 8000"
echo "Then add to the live system: deb http://<host>:8000 bookworm main"
