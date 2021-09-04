#!/bin/sh

set -e # fail out if any step fails
set -x

. ../setenv.sh

export CFLAGS="${CFLAGS} -DFAKE_ROOT"
if [ ! -d dropbear/.git ]
then
    git clone https://github.com/mkj/dropbear
fi
cp *.h dropbear
cd dropbear
echo '#define DEFAULT_PATH "/usr/bin:/bin:/system/bin:/system/sdcard/bin"' >> localoptions.h

autoconf; autoheader
./configure --host=mips-linux --disable-zlib
make clean
make PROGRAMS="dropbear ssh scp dropbearkey" MULTI=1 SCPPROGRESS=1

cp dropbearmulti ${INSTALLDIR}/bin