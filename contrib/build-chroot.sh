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
mkdir -p $build/chroot/etc/apt/sources.list.d

cat << 'EOF' > "$build/chroot/install.sh"
#!/usr/bin/env bash
set -x
set +e
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -q -y ca-certificates apt-transport-https curl
/install-repos.sh
/install-debs.sh
apt update && xargs apt install -q -y --no-install-recommends < /base.txt
apt update && xargs apt install -q -y < /packages.txt
adduser guy --quiet --disabled-password --gecos ""
chpasswd <<<"guy:guy"
gpasswd -a guy sudo
apt clean
EOF

echo "linux-image-$arch" > "$build/chroot/base.txt"
cat packages/base.txt >> "$build/chroot/base.txt"
cat packages/*-*.txt > "$build/chroot/packages.txt"

# loose debs
wget https://github.com/FreeTubeApp/FreeTube/releases/download/v0.16.0-beta/freetube_0.16.0_amd64.deb -O packages/freetube.deb


mkdir -p "$build/chroot/tmp/debs"
echo '#!/bin/bash' > "$build/chroot/install-debs.sh"
echo 'test $(find /tmp/debs/ | grep \\.deb$ -c ) != 0 || exit 0' >> "$build/chroot/install-debs.sh"
echo 'for f in /tmp/debs/*.deb ; do apt install "$f" ; done' >> "$build/chroot/install-debs.sh"
echo 'rm -rf /tmp/debs' >> "$build/chroot/install-debs.sh"
echo 'apt install -q -y -f' >> "$build/chroot/install-debs.sh"
chmod +x "$build/chroot/install-debs.sh"

echo '#!/bin/bash' > "$build/chroot/install-repos.sh"

# deb.oxen.io repo
echo 'curl -so /etc/apt/trusted.gpg.d/oxen.gpg https://deb.oxen.io/pub.gpg' >> "$build/chroot/install-repos.sh"
echo 'cat << "EOF" > etc/apt/sources.list.d/oxen.list' >> "$build/chroot/install-repos.sh"
echo 'deb https://deb.oxen.io bullseye main' >> "$build/chroot/install-repos.sh"
echo 'EOF' >> "$build/chroot/install-repos.sh"

# brave repo
echo 'curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg' >> "$build/chroot/install-repos.sh"
echo 'cat << "EOF" > /etc/apt/sources.list.d/brave.list' >> "$build/chroot/install-repos.sh"
echo 'deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main' >> "$build/chroot/install-repos.sh"
echo 'EOF' >> "$build/chroot/install-repos.sh"

# librewolf repo
echo 'curl -fsSLo /usr/share/keyrings/librewolf-keyring.gpg https://deb.librewolf.net/keyring.gpg' >> "$build/chroot/install-repos.sh"
echo 'cat << "EOF" > /etc/apt/sources.list.d/librewolf.list' >> "$build/chroot/install-repos.sh"
echo "deb [signed-by=/usr/share/keyrings/librewolf-keyring.gpg arch=amd64] https://deb.librewolf.net $release main" >> "$build/chroot/install-repos.sh"
echo 'EOF' >> "$build/chroot/install-repos.sh"

chmod +x "$build/chroot/install-repos.sh"

for f in packages/*.deb ; do
    cp "$f" "$build/chroot/tmp/debs"
done

chmod +x "$build/chroot/install.sh"
chroot "$build/chroot" /install.sh
rm -f "$build/chroot/install.sh" "$build/chroot/install-debs.sh" "$build/chroot/install-repos.sh" "$build/chroot/packages.txt" "$build/chroot/base.txt"

mkdir -p $build/chroot/var/lib/lokinet/conf.d
cp custom/lokinet/*.ini $build/chroot/var/lib/lokinet/conf.d
mkdir -p $build/chroot/etc/dnscrypt-proxy
cp custom/dnscrypt-proxy/{dnscrypt-proxy.toml,forwarding.txt} $build/chroot/etc/dnscrypt-proxy
