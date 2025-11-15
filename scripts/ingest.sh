#!/bin/sh

set -e

BASEURL=$1
ANNOUNCE=$2

if [ -z "$BASEURL" ] || [ -z "$ANNOUNCE" ]; then
	echo "ingest-all.sh BASEURL announce-mail"
	exit 1
fi

# Loop over pkgbase repos.
: > data/arches
cat "$2" |
    grep -E 'SHA256 \((.*-pkgbase-repo.*tar)\) = ([0-9a-f]*)' |
    sed -e 's/.*SHA256 //' |
    tr -d '()' |
    while read FILE EQ HASH; do
	TMP=${FILE%%-pkgbase-repo*}
	TARGET_ARCH=${TMP##*-}
	TUPLE=${TMP#FreeBSD-*-*-}
	TMP=${FILE%%-${TUPLE}*}
	VERS=${TMP#FreeBSD-}
	sh ingest-pkgrepo.sh "$BASEURL/PKGBASE-REPOS/$VERS/$TARGET_ARCH/Latest/FreeBSD-${VERS}-${TUPLE}-pkgbase-repo.tar" "$HASH"
done

# Fetch appropriate DVD image.
TARGET_ARCH=`uname -m`
cat "$2" |
    grep -E "SHA256.*${TARGET_ARCH}.*disc1.iso[)]" |
    sed -e 's/.*SHA256 //' |
    tr -d '()' |
    while read FILE EQ HASH; do
	TMP=${FILE#FreeBSD-}
	VERNUM=${TMP%%-*}
	sh ingest-disc1.sh "$BASEURL/ISO-IMAGES/$VERNUM/$FILE" $HASH
done
