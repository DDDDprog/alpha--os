# Alpha OS Live ISO (Debian-based)
Pro build and operations guide

Alpha OS is a Debian bookworm based live ISO built with live-build, featuring:
- XFCE desktop
- Live user: alpha (password: alpha)
- Firmware: main, contrib, non-free, non-free-firmware
- BIOS and UEFI boot (iso-hybrid)
- Persistence-ready
- Welcome dialog on login with quick actions

This README walks you through building, testing, customizing, and shipping the ISO like a pro.

----------------------------------------------------------------

## TL;DR

- Docker (recommended, clean and reproducible)
  - bash scripts/build-docker.sh
  - ISO lands in out/

- Native (Debian 12/Ubuntu 22.04+)
  - sudo bash scripts/prereqs-debian.sh
  - sudo bash scripts/build.sh
  - ISO lands in out/

- Test quickly (Linux with KVM)
  - qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -cdrom out/alpha-os-bookworm-amd64.iso -boot d

----------------------------------------------------------------

## Repository layout

- live-build/auto/config  Live-build configuration (calls "lb config noauto" to avoid recursion)
- live-build/config/      Package lists, includes, hooks, Calamares placeholders
- scripts/                Helper scripts (build, clean, diagnose, etc.)
- Dockerfile              Container definition for reliable builds
- out/                    Generated ISO artifacts (created after build)

Key components:
- XFCE desktop: task-xfce-desktop + goodies
- Display manager: lightdm + lightdm-gtk-greeter
- Live user: alpha / alpha, with passwordless sudo (live session convenience)
- Welcome: /usr/local/bin/alpha-welcome autostarts (network/info/installer hints)
- Wallpaper: /usr/share/backgrounds/alpha-os-wallpaper.png (sample included)

----------------------------------------------------------------

## One-time setup

After cloning or unzipping the repo, ensure scripts are executable:

\`\`\`
chmod +x live-build/auto/config
chmod +x live-build/config/hooks/normal/*.chroot
chmod +x live-build/config/includes.chroot/usr/local/bin/alpha-welcome
chmod +x scripts/*.sh
\`\`\`

If you pulled from a ZIP or some VCS, exec bits might be stripped — re-run the commands above.

----------------------------------------------------------------

## Build methods

### A) Build with Docker (recommended)

- Requires Docker with privileged containers (loop devices for image build)
- Produces consistent results across hosts

Steps:
\`\`\`
bash scripts/build-docker.sh
\`\`\`

Artifacts:
- out/*.iso
- Convenience copy: out/alpha-os-bookworm-amd64.iso

Note: The script runs:
- lb clean --purge
- lb config
- lb build
and copies the ISO out of the container.

### B) Build natively (Debian 12 or Ubuntu 22.04+)

1) Install prerequisites:
\`\`\`
sudo bash scripts/prereqs-debian.sh
\`\`\`

2) Build:
\`\`\`
sudo bash scripts/build.sh
\`\`\`

3) Find your ISO in:
- out/alpha-os-bookworm-amd64.iso

If you encounter errors, purge prior state and rebuild:
\`\`\`
sudo bash scripts/clean.sh
sudo bash scripts/build.sh
\`\`\`

----------------------------------------------------------------

## Running and testing the ISO

### QEMU (fast, no USB)

- With KVM (Linux):
\`\`\`
qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -cdrom out/alpha-os-bookworm-amd64.iso -boot d
\`\`\`

- Without KVM (portable, slower):
\`\`\`
qemu-system-x86_64 -m 4096 -smp 2 -cdrom out/alpha-os-bookworm-amd64.iso -boot d
\`\`\`

### Flash to USB (careful: destructive)

Identify your USB device (e.g., /dev/sdX):
\`\`\`
lsblk
sudo dd if=out/alpha-os-bookworm-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
sync
\`\`\`

Or use a GUI flasher (balenaEtcher, Raspberry Pi Imager, GNOME Disks).

### Verify checksums

Generate and verify SHA256:
\`\`\`
(cd out && sha256sum *.iso > SHA256SUMS)
(cd out && sha256sum -c SHA256SUMS)
\`\`\`

Optional: sign checksums (requires GPG key):
\`\`\`
(cd out && gpg --armor --detach-sign --output SHA256SUMS.asc SHA256SUMS)
\`\`\`

----------------------------------------------------------------

## Persistence (save changes on USB)

Alpha OS supports live persistence. After flashing the ISO to a USB:

1) Create a second partition on the USB (ext4 recommended) and label it persistence.
   Example using parted (replace sdX with your device):
\`\`\`
sudo parted /dev/sdX --script mkpart primary ext4 4GiB 100%
sudo mkfs.ext4 -L persistence /dev/sdX2
\`\`\`

2) Mount and add persistence.conf:
\`\`\`
sudo mkdir -p /mnt/persist
sudo mount /dev/sdX2 /mnt/persist
echo "/ union" | sudo tee /mnt/persist/persistence.conf
sudo umount /mnt/persist
\`\`\`

3) Boot the ISO with kernel parameter persistence (already added to bootappend defaults). If needed, press e in GRUB and ensure persistence is in the linux line.

----------------------------------------------------------------

## Customization

Where to change things:

- Packages:
  - live-build/config/package-lists/alpha-os.list.chroot
  - Enable optional installer profile by renaming:
    - mv live-build/config/package-lists/optional-calamares.list.chroot.disabled \
         live-build/config/package-lists/optional-calamares.list.chroot

- Live user, locale, timezone:
  - live-build/config/includes.chroot/etc/live/config.conf.d/alpha.conf

- Hooks (run inside chroot during build):
  - live-build/config/hooks/normal/*.chroot
  - Examples included for password, sudo, branding.

- Wallpaper and theming:
  - live-build/config/includes.chroot/usr/share/backgrounds/alpha-os-wallpaper.png
  - Branding hook adjusts LightDM greeter background.

- Boot parameters (defaults at build time):
  - live-build/auto/config: bootappend-live string
  - Current defaults: persistence locales=en_US.UTF-8 timezone=UTC keyboard-layouts=us

- Calamares installer (optional):
  - Packages: optional-calamares.list.chroot (disabled by default)
  - Minimal config: /etc/calamares/* (placeholders provided)
  - Availability can vary across mirrors; you may need backports or your own repo.

----------------------------------------------------------------

## Mirrors, caching, and speed

- Change mirrors (faster, regional):
  - live-build/auto/config flags:
    - --mirror-bootstrap, --mirror-chroot, --mirror-chroot-security, --mirror-binary
  - Example for a regional mirror:
    - --mirror-bootstrap http://ftp.<country-code>.debian.org/debian/

- HTTP caching (huge speedup across rebuilds):
  - Install apt-cacher-ng on the host and expose it on port 3142.
  - Then in auto/config, set mirrors to:
    - http://127.0.0.1:3142/deb.debian.org/debian
    - http://127.0.0.1:3142/security.debian.org/debian-security

- Reuse build cache: live-build caches packages between runs. If you need a clean slate:
  - lb clean --purge or use scripts/clean.sh

----------------------------------------------------------------

## Reproducibility tips

- Pin versions: maintain a snapshot sources.list pointing to snapshot.debian.org:
  - Example (advanced): replace mirrors with https://snapshot.debian.org/archive/debian/<date-time>/
- Record tool versions:
  - lb --version
  - debootstrap --version
- Use Docker builds on CI (see snippet below) to keep toolchain stable.

----------------------------------------------------------------

## Troubleshooting

- Recursion / flood of “P: Executing auto/config script.” or “tr: Argument list too long”:
  - Ensure live-build/auto/config calls:
    - lb config noauto ...
  - Ensure build scripts run:
    - lb config (not ./auto/config)
  - Purge and rebuild:
    - sudo bash scripts/clean.sh
    - sudo bash scripts/build.sh

- Missing firmware at runtime:
  - We include non-free-firmware. If hardware still fails, test with Secure Boot disabled (some firmware behaves differently).

- Build breaks on package not found:
  - Mirrors may be out-of-sync. Switch to main deb.debian.org or try another mirror.
  - Remove optional components (like Calamares) first, then add back.

- No space left on device:
  - Ensure 10–20GB free for build artifacts and chroot.

- ISO boots to black screen on UEFI with Secure Boot:
  - Try disabling Secure Boot in firmware for the first test.
  - Verify your hardware’s Secure Boot policies.

- LightDM greeter background didn’t change:
  - Confirm wallpaper exists at /usr/share/backgrounds/alpha-os-wallpaper.png
  - Examine /etc/lightdm/lightdm-gtk-greeter.conf

- Ubuntu-keyring error
  - Symptom: During chroot package installation you see:
    E: Package 'ubuntu-keyring' has no installation candidate
  - Fixes we ship by default:
    - We explicitly avoid meta tasks and install XFCE packages directly.
    - Recommends/Suggests are disabled in live-build and inside the chroot (apt.conf.d/01norecommends).
    - We block Ubuntu-only packages via apt pinning (preferences.d/99-no-ubuntu).
    - We disable any apt proxy/cacher within the chroot (apt.conf.d/99no-proxy), preventing host-side apt-cacher-ng from confusing repos.
  - What to do now:
    1) Purge and rebuild to ensure a clean state:
       sudo bash scripts/clean.sh
       sudo bash scripts/build.sh
       # Or use Docker: bash scripts/build-docker.sh
    2) If the error persists, search the build log for the culprit:
       grep -n "ubuntu-keyring" live-build/build.log | tail -n 5
       # Then share ~30 lines above and below the match so we can identify who depends on it.
    3) Double-check you don’t have any custom includes that add Ubuntu sources or packages.

Diagnostics:
\`\`\`
bash scripts/diagnose.sh
\`\`\`

Deep clean:
\`\`\`
bash scripts/clean.sh
\`\`\`

----------------------------------------------------------------

## Shipping and verification

- Checksums
\`\`\`
(cd out && sha256sum *.iso > SHA256SUMS && sha256sum -c SHA256SUMS)
\`\`\`

- Optional GPG signing (requires a GPG key)
\`\`\`
(cd out && gpg --armor --detach-sign --output SHA256SUMS.asc SHA256SUMS)
# Consumers verify:
gpg --verify out/SHA256SUMS.asc out/SHA256SUMS
sha256sum -c out/SHA256SUMS
\`\`\`

- Release artifacts
  - alpha-os-bookworm-amd64.iso
  - SHA256SUMS
  - SHA256SUMS.asc (optional)

----------------------------------------------------------------

## CI example (GitHub Actions, minimal)

Create .github/workflows/build.yml:

\`\`\`
name: Build ISO
on: [push, workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Build container image
        run: docker build -t alpha-os-live .
      - name: Build ISO
        run: docker run --rm --privileged -v ${{ github.workspace }}/live-build:/workspace/live-build -v ${{ github.workspace }}/out:/workspace/out alpha-os-live bash -lc 'lb clean --purge || true && lb config && lb build && cp -v *.iso /workspace/out/'
      - name: Checksums
        run: |
          cd out
          sha256sum *.iso > SHA256SUMS
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: alpha-os-iso
          path: out/*
\`\`\`

----------------------------------------------------------------

## Local APT repo (optional)

Bundle your own .deb packages and serve them:

1) Build a repo:
\`\`\`
bash scripts/make-apt-repo.sh ./my-debs ./alpha-repo
python3 -m http.server -d ./alpha-repo 8000
\`\`\`

2) Add to live system (at runtime):
\`\`\`
echo "deb http://<host-ip>:8000 bookworm main" | sudo tee /etc/apt/sources.list.d/alpha-local.list
sudo apt update
\`\`\`

3) Bake it into the ISO:
- Edit live-build/config/includes.chroot/etc/apt/sources.list.d/alpha-os.list and add your repo line.

----------------------------------------------------------------

## License

Unless specified otherwise within files, treat this repository as provided “as-is” without warranty. You may adapt and distribute your own Alpha OS images subject to Debian and included package licenses.

Happy building!
