#!/bin/sh

set -e # fail out if any step fails
set -x

if [ ! -d busybox/.git ]
then
  git clone --depth=1  git://git.busybox.net/busybox
fi

cd busybox
make clean
cp ../myconfig .config
#make CROSS_COMPILE=$CROSS_COMPILE menuconfig

sleep 1 # ensure timestamp delta

#Remove some packages that doesn't compile
#sed -i 's/CONFIG_FALLOCATE=y/CONFIG_FALLOCATE=n/' .config
#sed -i 's/CONFIG_NSENTER=y/CONFIG_NSENTER=n/' .config
#sed -i 's/CONFIG_FSYNC=y/CONFIG_FSYNC=n/' .config
#sed -i 's/CONFIG_SYNC=y/CONFIG_SYNC=n/' .config
#sed -i 's/CONFIG_TRACEROUTE=y/CONFIG_TRACEROUTE=n/' .config
#sed -i 's/CONFIG_TRACEROUTE6=y/CONFIG_TRACEROUTE6=n/' .config
#sed -i 's/CONFIG_TRACEROUTE_VERBOSE=y/CONFIG_TRACEROUTE_VERBOSE=n/' .config
#sed -i 's/CONFIG_TRACEROUTE_USE_ICMP=y/CONFIG_TRACEROUTE_USE_ICMP=n/' .config
#sed -i 's/# CONFIG_FLASH_ERASEALL is not set/CONFIG_FLASH_ERASEALL=y/' .config
make CROSS_COMPILE=$CROSS_COMPILE

cp busybox ${INSTALLDIR}/bin
