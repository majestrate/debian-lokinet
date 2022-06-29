#!/bin/bash

built=$(date +%s)
out=debian-lokinet-$(date +%s)
mkdir -p $out

cp lokinet-debian.iso $out/lokinet-debian-$built.iso

echo "debian lokinet iso" > $out/readme.txt
echo "packaged on $(date --date=@$built)" >> $out/readme.txt
echo "users:" >> $out/readme.txt
echo "guy:guy" >> $out/readme.txt

XZ_OPT='-T0' tar -cJvf $out.tar.xz $out
mktorrent -a udp://open.stealth.si:80/announce -a https://opentracker.i2p.rocks/announce $out.tar.xz
