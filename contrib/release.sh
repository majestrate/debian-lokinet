#!/bin/bash

built=$(date +%s)
out=debian-lokinet-$(date +%s)
mkdir -p $out

cp lokinet-debian.iso $out/lokinet-debian-$built.iso

echo "debian lokinet iso" > $out/readme.txt
echo "packaged on $(date --date=@$built)" >> $out/readme.txt
echo "users:" >> $out/readme.txt
echo "guy:guy" >> $out/readme.txt
echo "root:root" >> $out/readme.txt

tar -cJvf $out.tar.xz $out
mktorrent -a https://opentracker.i2p.rocks/announce $out.tar.xz
