#!/bin/sh

set -e

URL=$1
HASH=$2

if [ -z "$URL" ] || [ -z "$HASH" ]; then
	echo "usage: ingest-disc1.sh URL HASH"
	exit 1
fi

# Fetch and validate ISO
echo "Fetching $URL..."
fetch -q $URL -o data/${URL##*/}
sha256 -c $HASH data/${URL##*/}

# Extract the ISO
mkdir work/disc1
echo "Extracting ${URL##*/}..."
tar -xf data/${URL##*/} -C work/disc1
echo -n "Fixing directory permissions"
while ! find work/disc1 >/dev/null 2>/dev/null; do
	echo -n .
	find work/disc1 -type d -print0 2>/dev/null |
	    xargs -0 chmod u+rwx
done
echo

echo "Creating build root..."
mkdir work/disc1/buildroot
doas mountdev work/disc1/dev
chroot -n work/disc1 pkg -o IGNORE_OSVERSION=YES -o INSTALL_AS_USER=YES -R /usr/freebsd-packages/repos -r /buildroot install --glob -qy pkg 'FreeBSD-*'
chroot -n work/disc1 rm -r /buildroot/usr/src
doas umountdev work/disc1/dev
mv work/disc1/buildroot data/buildroot

# Garbage collect
rm -rf work/disc1
