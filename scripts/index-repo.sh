#!/bin/sh

set -e

DIR=$1
REPO=$2
INDEX=$3
FULLINDEX=$4
if [ -z "$DIR" ] || [ -z "$REPO" ] || [ -z "$INDEX" ] || [ -z "$FULLINDEX" ]; then
	echo "usage: index-repo.sh DIR REPO INDEX FULLINDEX"
	exit 1
fi

# Create buildroot for this indexing task
echo "Copying buildroot for $DIR/$REPO..."
mkdir work/buildroot.indexrepo
tar -cf- -C data/buildroot . | tar -xf- -C work/buildroot.indexrepo

# Copy in repo
echo "Copying in $DIR/$REPO..."
chroot -n work/buildroot.indexrepo mkdir /repo
tar -cf- -C $DIR/$REPO . |
    chroot -n work/buildroot.indexrepo tar -xf- -C /repo

# Index packages
echo "Indexing $DIR/$REPO..."
doas mountdev work/buildroot.indexrepo/dev
chroot -n work/buildroot.indexrepo \
    sh -c '
	cd /repo/*/latest;
	ls FreeBSD-*.pkg pkg-*.pkg 2>/dev/null |
	    while read pkg; do
		echo -n "$pkg "
		pkg query -F $pkg "%n %X"
	    done
    ' > $FULLINDEX
cut -f 2- -d ' ' < $FULLINDEX > $INDEX
doas umountdev work/buildroot.indexrepo/dev

# Garbage collect
rm -rf work/buildroot.indexrepo
