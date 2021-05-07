#!/usr/bin/env bash
set -x

test $(whoami) = root || exit 1

rm -rf build* *.iso
