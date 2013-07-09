#!/bin/ash

cd /tmp

wget http://downloads.openwrt.org/snapshots/trunk/ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin
wget http://downloads.openwrt.org/snapshots/trunk/ar71xx/md5sums

check=`md5sum -c md5sums 2> /dev/null | grep OK`

if [ -z "$check" ]; then
	echo "Invalid Checksum, aborting."
	exit 1
fi

echo "CheckSum Good, contining"

sysupgrade -v /tmp/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin
