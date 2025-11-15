#!/bin/sh

set -e

# Enter the staging tree to make life easier for ourselves
cd data/pubdir

# If we've never uploaded anything, set a dummy timestamp of 2000-01-01
if ! [ -f lastupload ]; then
	touch -t 200001010000.00 lastupload
fi

# Upload packages before repository metadata
find . -type f -newer lastupload -path '*/Hashed/*' |
    sed -e 's|^./||' |
    xargs -P 10 -I % \
	aws --profile upload s3 cp % s3://cloundfront.aws.pkgbase.freebsd.org/%
find . -type f -newer lastupload -not -path '*/Hashed/*' |
    sed -e 's|^./||' |
    xargs -P 10 -I % \
	aws --profile upload s3 cp % s3://cloundfront.aws.pkgbase.freebsd.org/%

# Timestamp the upload completion
touch lastupload
