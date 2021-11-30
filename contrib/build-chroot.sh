#!/usr/bin/env bash
set -x
set +e

test $(whoami) = root || exit 1

source ./contrib/vars.sh

mkdir -p "${build}"

debootstrap \
    --arch=$arch \
    --variant=minbase \
    ${release} \
    $build/chroot \
    http://ftp.us.debian.org/debian/


echo "lokinet-live" > $build/chroot/etc/hostname

mkdir -p $build/chroot/etc/apt/trusted.gpg.d
curl -so "$build/chroot/etc/apt/trusted.gpg.d/oxen.gpg" https://deb.oxen.io/pub.gpg

mkdir -p "$build/chroot/etc/apt/sources.list.d"
cat << 'EOF' > "$build/chroot/etc/apt/sources.list.d/oxen.list"
deb http://deb.loki bullseye main
EOF

cat << 'EOF' > "$build/chroot/install.sh"
#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
apt install -q -y ca-certificates
apt update && xargs apt install -q --no-install-recommends -y < /packages.txt
adduser guy --quiet --disabled-password --gecos ""
chpasswd <<<"root:root"
chpasswd <<<"guy:guy"

EOF

echo "linux-image-$arch" > "$build/chroot/packages.txt"
cat packages/*.txt >> "$build/chroot/packages.txt"

mkdir -p "$build/chroot/tmp/debs"
echo 'for f in /tmp/debs/*.deb ; do dpkg -i "$f" ; done' >> "$build/chroot/install.sh"
echo 'rm -rf /tmp/debs' >> "$build/chroot/install.sh"

for f in packages/*.deb ; do
    cp "$f" "$build/chroot/tmp/debs"
done

chmod +x "$build/chroot/install.sh"
chroot "$build/chroot" /install.sh
rm -f "$build/chroot/install.sh" "$build/chroot/packages.txt"

mkdir -p $build/chroot/var/lib/lokinet/conf.d
cp custom/lokinet/*.ini $build/chroot/var/lib/lokinet/conf.d
mkdir -p $build/chroot/etc/dnscrypt-proxy
cp custom/dnscrypt-proxy/{dnscrypt-proxy.toml,forwarding.txt} $build/chroot/etc/dnscrypt-proxy
