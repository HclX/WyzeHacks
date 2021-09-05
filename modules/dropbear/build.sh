#!/bin/sh

set -e # fail out if any step fails
set -x

. ../setenv.sh

export CFLAGS="${CFLAGS} -DFAKE_ROOT"
if [ ! -d .src/.git ]
then
    git clone https://github.com/mkj/dropbear .src
fi
cp *.h .src/

cd .src
autoconf; autoheader
./configure --host=mips-linux --disable-zlib
make clean
make PROGRAMS="dropbear ssh scp dropbearkey" MULTI=1 SCPPROGRESS=1

cp dropbearmulti ${INSTALLDIR}/bin
