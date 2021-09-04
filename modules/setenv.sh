#!/bin/sh
ROOTPATH=$(git rev-parse --show-toplevel)
echo "setting $ROOTPATH"

export TOOLCHAIN=${ROOTPATH}/modules/.tmp/mips-gcc472-glibc216-64bit-master/bin
export CROSS_COMPILE=$TOOLCHAIN/mips-linux-gnu-
export CC=${CROSS_COMPILE}gcc
export LD=${CROSS_COMPILE}ld
export CCLD=${CROSS_COMPILE}ld
export CXX=${CROSS_COMPILE}g++
export CXXLD=${CROSS_COMPILE}ld
export CPP=${CROSS_COMPILE}cpp
export CXXCPP=${CROSS_COMPILE}cpp
export AR=${CROSS_COMPILE}ar
export STRIP=${CROSS_COMPILE}strip

export CFLAGS="-muclibc -O3"
export CPPFLAGS="-muclibc -O3"
export CXXFLAGS="-muclibc -O3"
export LDFLAGS="-muclibc -O3"

export INSTALLDIR=${INSTALLDIR:-$ROOTPATH/modules}
