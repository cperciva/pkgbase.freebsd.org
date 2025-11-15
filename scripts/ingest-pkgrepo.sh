#!/bin/sh

set -e

URL=$1
HASH=$2

if [ -z "$URL" ] || [ -z "$HASH" ]; then
	echo "usage: sh ingest-pkgrepo.sh URL HASH"
	exit 1
fi

# Fetch and validate pkg repo tarball
echo "Fetching ${URL}..."
fetch -q $URL -o data/${URL##*/}
sha256 -c $HASH data/${URL##*/}

# Extract the repository
REPODIR=$(mktemp -d work/repo.XXXXXXXX)
echo "Extracting ${URL##*/}..."
tar -xf data/${URL##*/} -C ${REPODIR}

# Figure out which architecture we just fetched
if [ -n "$(ls ${REPODIR} | tr -d 'A-Za-z0-9:')" ]; then
	echo "PKG repo has invalid contents!"
	exit 1
fi
TARGET_ARCH=$(ls ${REPODIR} | cut -f 3 -d :)
ls ${REPODIR} > data/ABI.${TARGET_ARCH}
echo ${TARGET_ARCH} >> data/arches

# Rename the repo
mv ${REPODIR} work/repo.${TARGET_ARCH}.shipped
