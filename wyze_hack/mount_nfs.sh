#!/bin/sh

# Default configuration
NFS_ROOT="192.168.1.200:/volume1"

# User configuration
source $SCRIPT_DIR/config.inc

# Do not modify the rest of this script unless you know what you are doing.
NFS_MOUNT="mount -o nolock,rw"

# Delay start, to avoid racing
sleep 60

while true
do
    sleep 1
    MAC=`sed 's/://g' /sys/class/net/wlan0/address | tr a-z A-Z`

    if [ "${#MAC}" -ne "12" ];
    then
        echo "Unexpected MAC address:[$MAC], will retry..."
        continue
    fi

    if mount | grep -q "/dev/mmcblk0p1 on /media/mmcblk0p1";
    then
        echo "SD card mounted"
        if [ -f /media/mmcblk0p1/version.ini ];
        then
            echo "Stopping NFS mount..."
            exit
        fi
        
        echo "Unmounting SD card..."
        # Delay umount to avoid racing
        sleep 10
        if ! umount /media/mmcblk0p1;
        then
            echo "umount /media/mmcblk0p1 failed, will retry..."
            continue
        fi
    fi

    if [ ! -d /media/mmcblk0p1 ];
    then
        echo "/media/mmcblk0p1 doesn't exist, creating..."
        if ! mkdir -p /media/mmcblk0p1;
        then
            echo "mkdir -p /media/mmcblk0p1 failed, will retry..."
            continue
        fi
    fi

    CAM_DIR=WyzeCams/$MAC
    if mount | grep -q "$NFS_ROOT/$CAM_DIR on /media/mmcblk0p1";
    then
        echo "NFS share already mounted..."
        sleep 10
        continue
    fi

    if ! mount | grep -q "$NFS_ROOT on /mnt";
    then
        echo "Mounting $NFS_ROOT on /mnt..."
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
    if ! $NFS_MOUNT $NFS_ROOT/$CAM_DIR /media/mmcblk0p1;
    then
        echo "mount mount $NFS_ROOT/$CAM_DIR /media/mmcblk0p1 failed, will retry..."
        continue
    fi
done
