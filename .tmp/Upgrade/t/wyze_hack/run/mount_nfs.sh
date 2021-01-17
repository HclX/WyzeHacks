#!/bin/sh
if [ -z "$NFS_ROOT" ];
then
    echo "NFS_ROOT not configured, skipping NFS mount..."
    exit 1
fi

if [ -z "$DEVICE_ID" ];
then
    echo "Device ID not found in /params/config/.product_config!"
    exit 1
fi

# MMC detection GPIO number is 50
echo 1 > $WYZEHACK_DIR/mmc_gpio_value.txt
$WYZEHACK_DIR/bin/hackutils init 50

NFS_MOUNT="/bin/mount $NFS_OPTIONS"
while true
do
    sleep 10
    if ! ifconfig wlan0 | grep "inet addr";
    then
        echo "wlan0 not ready yet..."
        continue
    fi

    if ! pidof telnetd;
    then
        echo "Starting telnetd..."
        telnetd
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
        if [ -f "$DIR/.mac_$DEVICE_ID" ];
        then
            CAM_DIR="$DIR"
            break
        fi
    done

    echo Mounting directory $CAM_DIR as SD card
    if [ ! -d "$CAM_DIR" ];
    then
        echo "Creating data directory [$CAM_DIR]"
        if ! mkdir -p "$CAM_DIR";
        then
            echo "[mkdir -p $CAM_DIR] failed, will retry..."
            continue
        fi
    fi

    echo "Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmcblk0p1"
    mkdir -p /media/mmcblk0p1
    if ! mount -o bind "$CAM_DIR" /media/mmcblk0p1;
    then
        echo "mount $CAM_DIR as /media/mmcblk0p1 failed, will retry..."
        continue
    fi

    echo "Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmc"
    mkdir -p /media/mmc
    if ! mount -o bind "$CAM_DIR" /media/mmc;
    then
        echo "mount $CAM_DIR as /media/mmc failed, will retry..."
        continue
    fi

    touch /media/mmcblk0p1/.mac_$DEVICE_ID
    ifconfig > /media/mmcblk0p1/ifconfig.txt 2>&1

    echo "Notifying iCamera about SD card insertion event..."
    echo 0 > $WYZEHACK_DIR/mmc_gpio_value.txt
    $WYZEHACK_DIR/bin/hackutils mmc_insert
    break
done

# Keep a copy of config.inc in <cam_dir>/wyzehacks directory, this allows user
# to verify their current config and updating it by editing this file.
mkdir -p /media/mmc/wyzehacks
cp $WYZEHACK_CFG /media/mmc/wyzehacks/config.inc

$WYZEHACK_DIR/log_sync.sh &
$WYZEHACK_DIR/auto_reboot.sh &
$WYZEHACK_DIR/auto_archive.sh &

# This seems to be useful to prevent reboot caused by wifi dropping.
if [ "$PING_KEEPALIVE" == "1" ];then
    GATEWAY_IP=`route -n | grep "UG" | awk -F' ' '{print $2}'`
    echo "Trying to ping gateway $GATEWAY_IP..."
    ping $GATEWAY_IP 2>&1 >/dev/null &
fi

# Custom script
if [ -f "$CUSTOM_SCRIPT" ]; then
    echo "Starting custom script: $CUSTOM_SCRIPT"
    $CUSTOM_SCRIPT &
else
    echo "Custom script not found: $CUSTOM_SCRIPT"
fi

# Detecting NFS share mount failure
while true
do
    /bin/mount > /tmp/mount.txt
    if ! grep "/media/mmcblk0p1 type nfs" /tmp/mount.txt > /dev/null 2>&1;
    then
        echo "NFS no longer mounted as /media/mmcblk0p1"
        break
    fi

    if ! grep "/media/mmc type nfs" /tmp/mount.txt > /dev/null 2>&1;
    then
        echo "NFS no longer mounted as /media/mmc"
        break
    fi

    if ( timeout -t 60 df -h 2>&1| grep -q 'Stale NFS');
    then
        echo "Stale NFS handle detected"
        break
    fi

    # Check for every 10 seconds
    sleep 10
done

if [ ! -z "$NOTIFICATION_VOLUME" ];then
    $WYZEHACK_DIR/playwav.sh /usr/share/notify/CN/user_need_check.wav $NOTIFICATION_VOLUME
fi

# This will make the log sync flush logs
killall sleep
sync
sleep 3
/sbin/reboot
