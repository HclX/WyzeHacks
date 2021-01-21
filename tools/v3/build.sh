#!/bin/sh
if [ ! -f Upgrade/rootfs.bin ];then
    ./mkimage.sh firmwares/4.36.0.228/demo_wcv3.bin Upgrade/rootfs.bin
fi
tar --sort=name --owner=root:0 --group=root:0 --mtime='1970-01-01' --dereference -cf ../../installer/wcv3_init.bin Upgrade
