#!/usr/bin/env bash
set -x

test $(whoami) = root || exit 1

source ./contrib/vars.sh

mkdir -p "${build}"

debootstrap \
    --arch=$arch \
    --variant=minbase \
    ${release} \
    $build/chroot \
    http://ftp.us.debian.org/debian/

curl -so "${build}/chroot/etc/apt/trusted.gpg.d/oxen.gpg" https://deb.oxen.io/pub.gpg

cat "${build}/chroot/etc/apt/sources.list.d/oxen.list" <<EOF
deb https://deb.oxen.io ${release} main
EOF

cat "${build}/chroot/install.sh" <<EOF #!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
apt update && xargs apt install -q --no-install-recommends -y < /packages.txt 
adduser guy --quiet
chpasswd <<<"root:root"
chpasswd <<<"guy:guy"
EOF

echo "linux-image-${arch}" > "${build}/chroot/packages.txt"
cat packages/*.txt >> "${build}/chroot/packages.txt"

chroot "${build}/chroot" ./install.sh
rm -f "{$build}/chroot/install.sh" "${build}/chroot/packages.txt"

