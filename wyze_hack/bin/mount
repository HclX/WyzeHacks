#!/bin/sh
if echo "$@" | grep -q "/dev/mmcblk0p1";
then
    echo "Skipping SD card mounting..."
    exit
fi

if echo "$@" | grep -q "remount,rw /media/mmcblk0p1";
then
    echo "Skipping SD card remounting..."
    exit
fi

echo "Not SD card, passing through..."
/bin/mount "$@"
