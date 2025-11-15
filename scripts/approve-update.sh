#!/bin/sh

set -e

# Get a token using MFA device
sh -e gettoken.sh signing > work/awscreds

# Loop over each architecture
for ARCH in $(cat data/arches); do
	# Sort pkg indices
	sort < data/pkgindex.${ARCH} > work/pkgindex.${ARCH}.sorted
	sort < work/pkgindex.${ARCH}.built > work/pkgindex.${ARCH}.built.sorted
	sort < data/pkgindex.${ARCH}.full > work/pkgindex.${ARCH}.sorted.full
	sort < work/pkgindex.${ARCH}.built.full > work/pkgindex.${ARCH}.built.sorted.full

	echo -n "Removing old packages for ${ARCH}..."
	comm -13 work/pkgindex.${ARCH}.built.sorted work/pkgindex.${ARCH}.sorted |
	    grep ^FreeBSD- |
	    while read PKG HASH; do
		grep " $PKG $HASH" work/pkgindex.${ARCH}.sorted.full
	done > work/pkgs.${ARCH}.rm
	while read F PKG HASH; do
		echo -n " ${PKG}"
		rm data/pkgs.${ARCH}/${F}
	done < work/pkgs.${ARCH}.rm
	echo

	echo -n "Adding new packages for ${ARCH}..."
	comm -23 work/pkgindex.${ARCH}.built.sorted work/pkgindex.${ARCH}.sorted |
	    grep ^FreeBSD- |
	    while read PKG HASH; do
		grep " $PKG $HASH" work/pkgindex.${ARCH}.built.sorted.full
	done > work/pkgs.${ARCH}.cp
	while read F PKG HASH; do
		echo -n " ${PKG}"
		cp work/repo.${ARCH}.built/*/latest/${F} data/pkgs.${ARCH}
	done < work/pkgs.${ARCH}.cp
	echo

	# Construct new pkgindex
	comm -23 work/pkgindex.${ARCH}.sorted.full work/pkgs.${ARCH}.rm |
	    sort - work/pkgs.${ARCH}.cp > data/pkgindex.${ARCH}.full
	cut -f 2- -d ' ' < data/pkgindex.${ARCH}.full > data/pkgindex.${ARCH}

	# Clean up
	rm -r work/repo.${ARCH}.built
	rm work/pkgindex.${ARCH}.built work/pkgindex.${ARCH}.built.full
	rm work/pkgindex.${ARCH}.sorted work/pkgindex.${ARCH}.built.sorted
	rm work/pkgindex.${ARCH}.sorted.full work/pkgindex.${ARCH}.built.sorted.full
	rm work/pkgs.${ARCH}.rm work/pkgs.${ARCH}.cp

        # Generate repo
        rm -rf work/repo.${ARCH}.signed
        mkdir work/repo.${ARCH}.signed
        tar -cf- -C data/pkgs.${ARCH} . | tar -xf- -C work/repo.${ARCH}.signed
        pkg repo -h work/repo.${ARCH}.signed signing_command: `pwd`/sign.sh
done

# Clean up
rm work/awscreds
