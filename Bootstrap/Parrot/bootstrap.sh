#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <arch> <target-dir> [suite]" >&2
  exit 1
fi

ARCH="$1"
TARGET="$2"
SUITE="${3:-stable}"

if [[ -z "${TARGET}" || "${TARGET}" == "/" ]]; then
  echo "Error: target directory is missing or unsafe" >&2
  exit 1
fi

MIRROR="http://ba.mirror.garr.it/mirrors/parrot"

# Bootstrap the system
rm -rf "${TARGET}"
mkdir -p "${TARGET}"
if [[ "${ARCH}" == "i386" || "${ARCH}" == "amd64" ]]; then
  debootstrap --no-check-gpg --arch="${ARCH}" --variant=minbase \
    --include=busybox,systemd,libsystemd0,wget,ca-certificates,neofetch,udisks2,gvfs \
    "${SUITE}" "${TARGET}" "${MIRROR}"
else
  qemu-debootstrap --no-check-gpg --arch="${ARCH}" --variant=minbase \
    --include=busybox,systemd,libsystemd0,wget,ca-certificates,neofetch,udisks2,gvfs \
    "${SUITE}" "${TARGET}" "${MIRROR}"
fi

# Reduce size
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
  LC_ALL=C LANGUAGE=C LANG=C chroot "${TARGET}" apt-get clean

# Fix permission on dev machine only for easy packing
chmod -R 777 "${TARGET}"

# Setup DNS
{
  echo "127.0.0.1 localhost"
} > "${TARGET}/etc/hosts"
{
  echo "nameserver 8.8.8.8"
  echo "nameserver 8.8.4.4"
} > "${TARGET}/etc/resolv.conf"

# sources.list setup
rm -f "${TARGET}/etc/apt/sources.list"
{
  echo "deb ${MIRROR} ${SUITE} main contrib non-free"
  echo "deb-src ${MIRROR} ${SUITE} main contrib non-free"
} > "${TARGET}/etc/apt/sources.list"

# Import the gpg key, this is only required in Parrot Security OS
wget http://archive.parrotsec.org/parrot/misc/archive.gpg -O "${TARGET}/etc/apt/trusted.gpg.d/parrot-archive-key.asc"

# tar the rootfs
cd "${TARGET}"
rm -rf "../parrot-rootfs-${ARCH}.tar.xz"
rm -rf dev/*
XZ_OPT=-9 tar -cJvf "../parrot-rootfs-${ARCH}.tar.xz" ./*
