#!/bin/sh

set -e

ARCH=$1
SRCDIR=$2
if [ -z "$ARCH" ] || [ -z "$SRCDIR" ]; then
	echo "usage: build.sh ARCH SRCDIR"
	exit 1
fi

# Create buildroot for this build
echo "Copying buildroot for $ARCH..."
mkdir work/buildroot.$ARCH
tar -cf- -C data/buildroot . | tar -xf- -C work/buildroot.$ARCH

# Copy in src tree
echo "Copying in src tree for $ARCH..."
chroot -n work/buildroot.$ARCH mkdir /usr/src
tar -cf- -C $SRCDIR . |
    chroot -n work/buildroot.$ARCH tar -xf- -C /usr/src

# Do the build
echo "Building $ARCH..."
doas mountdev work/buildroot.$ARCH/dev
chroot -n work/buildroot.$ARCH make -C /usr/src buildworld buildkernel TARGET_ARCH=$ARCH NO_ROOT=YES WITHOUT_QEMU=YES -j$(sysctl -n hw.ncpu) > logs/build.log.$ARCH 2>&1
chroot -n work/buildroot.$ARCH make -C /usr/src packages TARGET_ARCH=$ARCH NO_ROOT=YES WITHOUT_QEMU=YES PKG_CTHREADS=4 -j$(sysctl -n hw.ncpu) >> logs/build.log.$ARCH 2>&1
doas umountdev work/buildroot.$ARCH/dev

# Extract the built repo
mv work/buildroot.$ARCH/usr/obj/usr/src/repo work/repo.$ARCH.built

# Garbage collect
rm -rf work/buildroot.$ARCH
