#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

if [ -z "$NFS_ROOT" ];
then
    echo "NFS_ROOT not configured, skipping NFS mount..."
    exit 1
fi

NFS_MOUNT="/bin/mount -o nolock,rw"

DEVICE_ID=`grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g'`
if [ -z "$DEVICE_ID" ];
then
    echo "Device ID not found in /params/config/.product_config!"
    exit 1
fi

while true
do
    sleep 10
    if ! ifconfig wlan0 | grep "inet addr";
    then
        echo "wlan0 not ready yet..."
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

    CAM_DIR=/mnt/WyzeCams/$DEVICE_ID
    for DIR in /mnt/WyzeCams/*/;
    do
        if [ -f $DIR/.mac_$DEVICE_ID ];
        then
            CAM_DIR=$DIR
            break
        fi
    done

    echo Mounting directory $CAM_DIR as SD card
    if [ ! -d $CAM_DIR ];
    then
        echo "Creating data directory [$CAM_DIR]"
        if ! mkdir -p $CAM_DIR;
        then
            echo "[mkdir -p $CAM_DIR] failed, will retry..."
            continue
        fi
    fi

    echo "Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmcblk0p1"
    mkdir -p /media/mmcblk0p1
    if ! mount -o bind $CAM_DIR /media/mmcblk0p1;
    then
        echo "mount $CAM_DIR as /media/mmcblk0p1 failed, will retry..."
        continue
    fi

    touch /media/mmcblk0p1/.mac_$DEVICE_ID
    ifconfig > /media/mmcblk0p1/ifconfig.txt 2>&1

    echo "Notifying iCamera about SD card insertion event..."
    touch /dev/mmcblk0
    touch /dev/mmcblk0p1
    $SCRIPT_DIR/bin/uevent_send "add@/devices/platform/jzmmc_v1.2.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0/mmcblk0p1"

    break
done

$SCRIPT_DIR/log_sync.sh &
$SCRIPT_DIR/auto_reboot.sh &
$SCRIPT_DIR/auto_archive.sh &

