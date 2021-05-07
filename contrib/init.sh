#!/usr/bin/env bash
set -x

test $(whoami) = root || exit 1

apt update && apt install -y debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    curl

