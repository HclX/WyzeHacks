#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

# Default configuration
NFS_ROOT="192.168.1.200:/volume1"

# User configuration
source $SCRIPT_DIR/config.inc

# Do not modify the rest of this script unless you know what you are doing.
NFS_MOUNT="/bin/mount -o nolock,rw"

while true
do
    sleep 10
    MAC=`sed 's/://g' /sys/class/net/wlan0/address | tr a-z A-Z`

    if [ "${#MAC}" -ne "12" ];
    then
        echo "Unexpected MAC address:[$MAC], will retry..."
        continue
    fi

    CAM_DIR=WyzeCams/$MAC
    if /bin/mount | grep -q "$NFS_ROOT/$CAM_DIR";
    then
        echo "NFS already mounted..."
        sleep 60
        continue
    fi

    if ! /bin/mount | grep -q "$NFS_ROOT on /mnt";
    then
        echo "$NFS_ROOT not mounted, try mounting to /mnt..."
        if ! $NFS_MOUNT $NFS_ROOT /mnt;
        then
            echo "[$NFS_MOUNT $NFS_ROOT /mnt] failed, will retry..."
            continue
        fi
    fi

    if [ ! -d /mnt/$CAM_DIR ];
    then
        echo "Creating data directory [/mnt/$CAM_DIR]"
        if ! mkdir -p /mnt/$CAM_DIR;
        then
            echo "[mkdir -p /mnt/$CAM_DIR] failed, will retry..."
            continue
        fi
    fi

    echo "Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmcblk0p1"
    mkdir -p /media/mmcblk0p1
    if ! $NFS_MOUNT $NFS_ROOT/$CAM_DIR /media/mmcblk0p1;
    then
        echo "mount mount $NFS_ROOT/$CAM_DIR /media/mmcblk0p1 failed, will retry..."
        continue
    fi

    ifconfig > /media/mmcblk0p1/ifconfig.txt 2>&1

    echo "Notifying iCamera about SD card insertion event..."
    touch /dev/mmcblk0
    touch /dev/mmcblk0p1
    $SCRIPT_DIR/uevent_send "add@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0/mmcblk0p1"
done
