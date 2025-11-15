#!/bin/sh

set -e

# Read PUBNAME
PUBNAME=$(cat data/pubname)

# If we were given a publishing name, use that one instead
if [ -n "$1" ]; then
	PUBNAME=$1
fi

# Copy trees one by one
for ARCH in $(cat data/arches); do
	ABI=$(cat "data/ABI.${ARCH}")
	mkdir -p "data/pubdir/${ABI}/${PUBNAME}"
	( cd work/repo.${ARCH}.signed && find .) |
	    sort |
	    while read P; do
		P1=work/repo.${ARCH}.signed/${P}
		P2=data/pubdir/${ABI}/${PUBNAME}/${P}
		if [ -d ${P1} ]; then
			mkdir -p ${P2}
			continue
		fi
		if [ -f ${P2} ] && cmp -s ${P1} ${P2}; then
			# Don't copy unchanged files; otherwise we'll bump
			# the timestamp and slow down upload.sh.
			continue
		fi
		cp ${P1} ${P2}
	done
done
