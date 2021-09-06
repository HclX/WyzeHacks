#!/bin/sh

set -e # fail out if any step fails
set -x

. ../setenv.sh

if [ ! -d .src/.git ]
then
  git clone --depth=1 git://git.busybox.net/busybox --branch 1_33_stable .src
fi

cp myconfig .src/.config
make CROSS_COMPILE=$CROSS_COMPILE -C .src clean all
cp .src/busybox ${INSTALLDIR}/bin
