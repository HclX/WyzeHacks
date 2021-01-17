#!/bin/sh
if echo "$@" | grep -q "/dev/mmcblk0p1";
then
    echo '/dev/mmcblk0p1: UUID="98BF-D9A9" TYPE="vfat"'
else
    /sbin/blkid "$@"
fi
