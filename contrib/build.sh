#!/usr/bin/env bash
set -x

test $(whoami) = root || exit 1

./contrib/build-chroot.sh || exit 1
./contrib/build-iso.sh "$(pwd)/lokinet-debian.iso" || exit 1
