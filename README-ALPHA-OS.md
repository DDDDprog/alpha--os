Alpha OS (Debian-based) - Live ISO with live-build

Overview
- Base: Debian bookworm (stable)
- Desktop: XFCE (task-xfce-desktop with extras)
- Live user: alpha (password: alpha)
- Firmware: main, contrib, non-free, non-free-firmware enabled
- Boot: BIOS and UEFI (Secure Boot enabled via signed GRUB packages)

Repo layout
- live-build/auto/config       # lb config options
- live-build/config/*          # package lists, hooks, includes
- scripts/build.sh             # native build on Debian/Ubuntu (root)
- scripts/build-docker.sh      # Docker-based build (requires --privileged)
- Dockerfile                   # container image to build the ISO
- out/                         # ISO output (created after build)

What you get
- Debian bookworm live ISO with XFCE
- Live user: alpha / alpha
- Persistence support (boot param: persistence)
- Welcome dialog on login (installer/network/info)
- Optional Calamares installer profile (disabled by default)
- Docker and native build paths
- APT repo stub and helper script

Quick start (Docker) - Recommended
1) Install Docker
2) bash scripts/build-docker.sh
3) ISO in out/

Quick start (native)
1) On Debian 12 or Ubuntu 22.04+:
   sudo bash scripts/prereqs-debian.sh
2) sudo bash scripts/build.sh
3) ISO in out/

Customization
- Packages: edit live-build/config/package-lists/alpha-os.list.chroot
- Live user, locale, timezone: live-build/config/includes.chroot/etc/live/config.conf.d/alpha.conf
- Hooks (chroot-time customization): live-build/config/hooks/normal/*.chroot
- Wallpaper: live-build/config/includes.chroot/usr/share/backgrounds/alpha-os-wallpaper.png
- Display manager: this config uses lightdm; adjust greeter config in the 040-branding hook if needed.

Persistence
- After writing ISO to USB, create a second partition labeled 'persistence' (ext4 recommended).
- Create /persistence.conf with:
    / union
- Boot with kernel parameter: persistence

APT repo (optional)
- Build a simple local repo from your .deb files:
  bash scripts/make-apt-repo.sh ./my-debs ./alpha-repo
  python3 -m http.server -d ./alpha-repo 8000
- Then on the live system:
  echo "deb http://<your-host>:8000 bookworm main" | sudo tee /etc/apt/sources.list.d/alpha-local.list
  sudo apt update

Enable the installer (Calamares)
- Calamares can be missing or outdated on some mirrors.
- To try it:
  mv live-build/config/package-lists/optional-calamares.list.chroot.disabled \
     live-build/config/package-lists/optional-calamares.list.chroot
  Then rebuild. Calamares config lives in /etc/calamares (minimal sample).

Clean and diagnose
- Deep clean: bash scripts/clean.sh
- Diagnose env: bash scripts/diagnose.sh

Fix for lb recursion
We prevent recursion by using 'lb config noauto' in live-build/auto/config, and invoking 'lb config' from scripts. If you still see multiple "P: Executing auto/config script." lines, ensure auto/config matches this repo and re-run a purge clean.

Common issues
- Recursion in lb config: ensure auto/config uses 'noauto' and use scripts to run lb config.
- Package not found (Calamares): keep it optional or use your own repo/backports.
- UEFI/Secure Boot: ISO should boot on UEFI and BIOS; disable Secure Boot if firmware complains.
