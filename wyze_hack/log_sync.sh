#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

while true
do
    sleep 60

    LOGSIZE=`wc /tmp/boot.log -c| awk '{print $1}'`
    if [ "$LOGSIZE" -lt "1000000" ];
    then
        continue
    fi

    cp /tmp/boot.log /tmp/boot1.log
    echo "Log truncated" > /tmp/boot.log

    if ! /bin/mount | grep -q "/media/mmcblk0p1";
    then
        echo "SD card not mounted, skipping"
        continue
    fi

    mkdir -p /media/mmcblk0p1/logs
    cp /tmp/boot1.log /media/mmcblk0p1/logs/boot_`date +"%Y_%m_%d_%H_%M_%S"`.log
done
