# Containerized build for Alpha OS live ISO (reliable environment)
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      live-build debootstrap xorriso squashfs-tools syslinux-efi \
      grub-pc-bin grub-efi-amd64-bin ca-certificates apt-transport-https \
      locales dosfstools mtools && \
    rm -rf /var/lib/apt/lists/*

# Locale
RUN sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen

WORKDIR /workspace

# Copy live-build tree
COPY live-build /workspace/live-build

# Ensure executables
RUN chmod +x /workspace/live-build/auto/config || true && \
    find /workspace/live-build/config/hooks -type f -name "*.chroot" -exec chmod +x {} \; || true && \
    chmod +x /workspace/live-build/config/includes.chroot/usr/local/bin/alpha-welcome || true

WORKDIR /workspace/live-build

# Default command builds the ISO
CMD bash -lc "lb clean --purge || true && lb config && lb build && ls -l *.iso"
