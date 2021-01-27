#!/bin/sh

# V3
VER=4.36.0.228
if [ ! -f Upgrade/rootfs_$VER.bin ]; then
    ./mkimage.sh firmwares/$VER/demo_wcv3.bin $((0x1F0040)) $((0x3D0000)) firmwares/$VER/rcS Upgrade/rootfs_$VER.bin
fi

# PAN
VER=4.10.6.218
if [ ! -f Upgrade/rootfs_$VER.bin ]; then
    ./mkimage.sh firmwares/$VER/demo.bin $((0x200040)) $((0x350000)) firmwares/$VER/rcS Upgrade/rootfs_$VER.bin
fi

# V2
VER=4.9.6.218
if [ ! -f Upgrade/rootfs_$VER.bin ]; then
    ./mkimage.sh firmwares/$VER/demo.bin $((0x200040)) $((0x350000)) firmwares/$VER/rcS Upgrade/rootfs_$VER.bin
fi

tar --sort=name --owner=root:0 --group=root:0 --mtime='1970-01-01' --dereference -cf ../installer/hack_init.bin Upgrade
