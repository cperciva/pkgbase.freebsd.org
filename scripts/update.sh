#!/bin/sh

set -e

# Construct patched src tree
echo "Constructing patched src tree..."
mkdir work/buildroot.src
tar -cf- -C data/buildroot . | tar -xf- -C work/buildroot.src
chroot -n work/buildroot.src mkdir /usr/src
tar -cf- -C data/src . |
    chroot -n work/buildroot.src tar -xf- -C /usr/src
doas mountdev work/buildroot.src/dev
chroot -n work/buildroot.src git -C /usr/src config user.email "re@FreeBSD.org"
chroot -n work/buildroot.src git -C /usr/src config user.name "FreeBSD pkgbase repo builder"
if ls patches | grep .; then
	for pfile in patches/*; do
		echo "Applying patch $pfile..."
		cat $pfile |
		   chroot -n work/buildroot.src git -C /usr/src am
	done
fi
doas umountdev work/buildroot.src/dev
mkdir work/src.patched
chroot -n work/buildroot.src tar -cf- -C /usr/src . |
    tar -xf- -C work/src.patched

# Build for all architectures
for ARCH in $(cat data/arches); do
	sh -e build.sh $ARCH work/src.patched
done

# Index built repositories
for ARCH in $(cat data/arches); do
	sh index-repo.sh work repo.$ARCH.built work/pkgindex.$ARCH.built work/pkgindex.$ARCH.built.full
done

# Compare built vs previous repositories
for ARCH in $(cat data/arches); do
	echo "Changes in $ARCH repository:"
	diff -u data/pkgindex.$ARCH work/pkgindex.$ARCH.built || true
done

# Garbage collect
rm -rf work/buildroot.src work/src.patched
