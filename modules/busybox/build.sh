#!/bin/sh

set -e # fail out if any step fails
set -x

. ../setenv.sh

if [ ! -d busybox/.git ]
then
  git clone --depth=1  git://git.busybox.net/busybox
fi

cd busybox
make clean
cp ../myconfig .config
make CROSS_COMPILE=$CROSS_COMPILE
cp busybox ${INSTALLDIR}/bin
