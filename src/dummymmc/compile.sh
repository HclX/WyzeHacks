#!/bin/sh
export CROSS_COMPILE=$(pwd)/../toolchain/bin/mips-linux-gnu-
pushd ../kernel && make modules_prepare
popd
make clean
make
