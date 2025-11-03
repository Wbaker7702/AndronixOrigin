#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <arch> <target-dir> [suite]" >&2
  exit 1
fi

ARCH="$1"
TARGET="$2"
SUITE="${3:-bionic}"

if [[ -z "${TARGET}" || "${TARGET}" == "/" ]]; then
  echo "Error: target directory is missing or unsafe" >&2
  exit 1
fi

MIRROR_PRIMARY="http://archive.ubuntu.com/ubuntu"
MIRROR_PORTS="http://ports.ubuntu.com/ubuntu-ports"

# Bootstrap the system
rm -rf "${TARGET}"
mkdir -p "${TARGET}"
if [[ "${ARCH}" == "i386" || "${ARCH}" == "amd64" ]]; then
  debootstrap --no-check-gpg --arch="${ARCH}" --variant=minbase \
    --include=systemd,libsystemd0,libnss-systemd,systemd-sysv,wget,ca-certificates,udisks2,gvfs \
    "${SUITE}" "${TARGET}" "${MIRROR_PRIMARY}"
else
  qemu-debootstrap --no-check-gpg --arch="${ARCH}" --variant=minbase \
    --include=systemd,libsystemd0,libnss-systemd,systemd-sysv,wget,ca-certificates,udisks2,gvfs \
    "${SUITE}" "${TARGET}" "${MIRROR_PORTS}"
fi

# Reduce size
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
  LC_ALL=C LANGUAGE=C LANG=C chroot "${TARGET}" apt-get clean

# Fix permission on dev machine only for easy packing
chmod -R 777 "${TARGET}"

# This step is only needed for Ubuntu to prevent Group error
touch "${TARGET}/root/.hushlogin"

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
if [[ "${ARCH}" == "i386" || "${ARCH}" == "amd64" ]]; then
  MIRROR="${MIRROR_PRIMARY}"
else
  MIRROR="${MIRROR_PORTS}"
fi
{
  echo "deb ${MIRROR} ${SUITE} main restricted universe multiverse"
  echo "deb-src ${MIRROR} ${SUITE} main restricted universe multiverse"
} > "${TARGET}/etc/apt/sources.list"

# tar the rootfs
cd "${TARGET}"
rm -rf "../ubuntu-rootfs-${ARCH}.tar.xz"
rm -rf dev/*
XZ_OPT=-9 tar -cJvf "../ubuntu-rootfs-${ARCH}.tar.xz" ./*
