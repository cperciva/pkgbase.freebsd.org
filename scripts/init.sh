#!/bin/sh

set -e

BUILDTYPE=$1
ANNOUNCE=$2
PORTSBRANCH=$3
SRCBRANCH=$4
SRCCOMMIT=$5
KEYID=$6
MFAID=$7
PUBDIR=$8
PUBNAME=$9

if [ -z "$BUILDTYPE" ] || [ -z "$ANNOUNCE" ] || [ -z "$PORTSBRANCH" ] ||
    [ -z "$SRCBRANCH" ] || [ -z "$SRCCOMMIT" ] || [ -z "$KEYID" ] ||
    [ -z "$MFAID" ] || [ -z "$PUBDIR" ] || [ -z "$PUBNAME" ]; then
	echo "init.sh BUILDTYPE announce-mail PORTSBRANCH SRCBRANCH SRCCOMMIT KEYID MFAID PUBDIR PUBNAME"
	exit 1
fi

# Create directories
mkdir data work logs patches

# Store parameters for staging
mkdir -p "${PUBDIR}"
ln -s $(realpath "${PUBDIR}") data/pubdir
echo "${PUBNAME}" > data/pubname

# Set up AWS credentials
echo "${MFAID}" > data/mfaid

# Get session token with MFA ID
sh -e gettoken.sh signing > work/awscreds

# Get public key
echo "${KEYID}" > data/keyid
(
	. work/awscreds
	aws kms get-public-key --key-id "${KEYID}" --output text | \
	    head -1 |
	    awk '{print $NF}' |
	    base64 -d |
	    openssl rsa -inform DER -pubin -pubout -out data/repo.pub
)

# Delete temporary credentials
rm work/awscreds

# Ingest everything
sh -e ingest.sh https://download.freebsd.org/$BUILDTYPE $ANNOUNCE

# Index shipped repositories
for ARCH in $(cat data/arches); do
	sh index-repo.sh work repo.$ARCH.shipped work/pkgindex.$ARCH.shipped work/pkgindex.$ARCH.shipped.full
done

# Build git
sh -e build-git.sh $PORTSBRANCH

# Check out src
git clone --branch ${SRCBRANCH} https://git.freebsd.org/src.git data/src
git -C data/src reset --hard ${SRCCOMMIT}
echo ${SRCCOMMIT} > data/srcommit

# Rebuild all of the architectures
for ARCH in $(cat data/arches); do
	sh build.sh $ARCH data/src
done

# Index built repositories
for ARCH in $(cat data/arches); do
	sh index-repo.sh work repo.$ARCH.built work/pkgindex.$ARCH.built work/pkgindex.$ARCH.built.full
done

# Compare shipped vs rebuilt repositories
for ARCH in $(cat data/arches); do
	echo "Differences in $ARCH repository:"
	diff -u work/pkgindex.$ARCH.shipped work/pkgindex.$ARCH.built || true
done
