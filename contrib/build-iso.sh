#!/usr/bin/env bash
set -x

test $(whoami) = root || exit 1

source ./contrib/var.sh

mkdir -p ${build}/{staging/{EFI/boot,boot/grub/x86_64-efi,isolinux,live},tmp}
mksquashfs \
    ${build}/chroot \
    ${build}/staging/live/filesystem.squashfs \
    -e boot

cp ${build}/chroot/boot/vmlinuz-* \
   ${build}/staging/live/vmlinuz && \
cp ${build}/chroot/boot/initrd.img-* \
   ${build}/staging/live/initrd


cat <<'EOF' >${build}/staging/isolinux/isolinux.cfg
UI vesamenu.c32

MENU TITLE Boot Menu
DEFAULT linux
TIMEOUT 600
MENU RESOLUTION 640 480
MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #9033ccff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std

LABEL linux
  MENU LABEL Lokinet Debian [BIOS/ISOLINUX]
  MENU DEFAULT
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live

LABEL linux
  MENU LABEL Lokinet Debian [BIOS/ISOLINUX] (nomodeset)
  MENU DEFAULT
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live nomodeset
EOF

cat <<'EOF' >${build}/staging/boot/grub/grub.cfg
search --set=root --file /DEBIAN_CUSTOM

set default="0"
set timeout=30

# If X has issues finding screens, experiment with/without nomodeset.

menuentry "Lokinet Debian [EFI/GRUB]" {
    linux ($root)/live/vmlinuz boot=live
    initrd ($root)/live/initrd
}

menuentry "Lokinet Debian [EFI/GRUB] (nomodeset)" {
    linux ($root)/live/vmlinuz boot=live nomodeset
    initrd ($root)/live/initrd
}
EOF

cat <<'EOF' >${build}/tmp/grub-standalone.cfg
search --set=root --file /DEBIAN_CUSTOM
set prefix=($root)/boot/grub/
configfile /boot/grub/grub.cfg
EOF

cp /usr/lib/ISOLINUX/isolinux.bin "${build}/staging/isolinux/" && \
cp /usr/lib/syslinux/modules/bios/* "${build}/staging/isolinux/"

# TODO: change these for arm

cp -r /usr/lib/grub/x86_64-efi/* "${build}/staging/boot/grub/x86_64-efi/"

grub-mkstandalone \
    --format=x86_64-efi \
    --output=$build/tmp/bootx64.efi \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=$build/tmp/grub-standalone.cfg"

(cd $build/staging/EFI/boot && \
    dd if=/dev/zero of=efiboot.img bs=1M count=20 && \
    mkfs.vfat efiboot.img && \
    mmd -i efiboot.img efi efi/boot && \
    mcopy -vi efiboot.img $build/tmp/bootx64.efi ::efi/boot/
)

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "$1" \
    -full-iso9660-filenames \
    -volid "DEBIAN_CUSTOM" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-boot \
        isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog isolinux/isolinux.cat \
    -eltorito-alt-boot \
        -e /EFI/boot/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 0xef ${build}/staging/EFI/boot/efiboot.img \
    "${build}/staging"
