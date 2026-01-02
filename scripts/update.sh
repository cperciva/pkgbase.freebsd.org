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
		BHEAD=$(git bundle list-heads patches/p0001.bundle | awk '{ print $2 }')
		tar -cf- $pfile | chroot -n work/buildroot.src tar -xf- -C /root/
		chroot -n work/buildroot.src git -C /usr/src pull /root/$pfile \
		    ${BHEAD}
		chroot -n work/buildroot.src rm /root/$pfile
	done
fi
chroot -n work/buildroot.src git -C /usr/src log --pretty=oneline $(cat data/srccommit)..@
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
