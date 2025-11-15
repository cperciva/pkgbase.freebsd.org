#!/bin/sh

set -e

PORTSBRANCH=$1
if [ -z "$PORTSBRANCH" ]; then
	echo "usage: build-git.sh PORTSBRANCH"
	exit 1
fi

# Get a ports tree
echo "Cloning ports tree..."
git clone --branch ${PORTSBRANCH} https://git.freebsd.org/ports.git data/ports

# Create a build chroot
echo "Copying buildroot for git build..."
mkdir work/buildroot.git
tar -cf- -C data/buildroot . | tar -xf- -C work/buildroot.git

# Copy in ports tree
echo "Copying ports tree for git build..."
chroot -n work/buildroot.git mkdir /usr/ports
tar -cf- -C data/ports . | chroot -n work/buildroot.git tar -xf- -C /usr/ports

# Options for building and installing git and dependencies
export I_DONT_CARE_IF_MY_BUILDS_TARGET_THE_WRONG_RELEASE=YES
export IGNORE_OSVERSION=YES
export BATCH=YES
export OPTIONS_UNSET="CONTRIB CURL DOCS GITWEB ICONF NLS PCRE2 PERL SEND_EMAIL SUBTREE INFO"
export INSTALL_AS_USER=YES

# Mount /dev and fetch distfiles
echo "Building git..."
doas mountdev work/buildroot.git/dev
tar -cf- -C /etc resolv.conf | chroot -n work/buildroot.git tar -xf- -C /etc
chroot -n work/buildroot.git make -C /usr/ports/devel/git fetch-recursive >> logs/git-fetch.log 2>&1
chroot -n work/buildroot.git rm /etc/resolv.conf

# Build git package and unmount /dev
chroot -n work/buildroot.git make -C /usr/ports/devel/git package >> logs/git-build.log 2>&1
chroot -n work/buildroot.git sh -c 'cat /usr/ports/devel/git/work-default/pkg/git*.pkg' > data/git.pkg
doas umountdev work/buildroot.git/dev

# Install package into clean buildroot
echo "Installing git into clean buildroot..."
# XXX pw is broken with unprivileged chroot
#doas mountdev buildroot/dev
#cat git.pkg | chroot -n buildroot pkg -o IGNORE_OSVERSION=YES -o INSTALL_AS_USER=YES add -
#doas umountdev buildroot/dev
cat data/git.pkg | pkg -r data/buildroot add -q - > logs/git-install 2>&1

# Clean up
rm -rf work/buildroot.git
