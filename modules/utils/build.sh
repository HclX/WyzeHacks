#!/bin/sh

set -e # fail out if any step fails
set -x

. ../setenv.sh

make clean
make all


