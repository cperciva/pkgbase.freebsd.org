#!/bin/sh

set -e

# Get a token using MFA device
sh -e gettoken.sh signing > work/awscreds

# Loop over each architecture
for ARCH in $(cat data/arches); do
	# Copy packages and indices into place
	mkdir data/pkgs.${ARCH}
	mv work/repo.${ARCH}.shipped/*/latest/FreeBSD-*.pkg data/pkgs.${ARCH}
	mv work/repo.${ARCH}.shipped/*/latest/pkg-*.pkg data/pkgs.${ARCH}
	mv work/pkgindex.${ARCH}.shipped data/pkgindex.${ARCH}
	mv work/pkgindex.${ARCH}.shipped.full data/pkgindex.${ARCH}.full

	# Garbage collect
	rm -rf work/repo.${ARCH}.shipped
	rm -rf work/repo.${ARCH}.built
	rm work/pkgindex.${ARCH}.built
	rm work/pkgindex.${ARCH}.built.full

	# Generate repo
	rm -rf work/repo.${ARCH}.signed
	mkdir work/repo.${ARCH}.signed
	tar -cf- -C data/pkgs.${ARCH} . | tar -xf- -C work/repo.${ARCH}.signed
	pkg repo -h work/repo.${ARCH}.signed signing_command: `pwd`/sign.sh
done

# Clean up
rm work/awscreds
