#!/bin/sh
export CROSS_COMPILE=$(pwd)/../toolchain/bin/mips-linux-gnu-
make clean
make
