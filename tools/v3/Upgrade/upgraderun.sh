#!/bin/sh
set -x

SCRIPT=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT`

SD_DIR=/media/mmcblk0p1
if [ ! -d $SD_DIR ];
then
    SD_DIR=/media/mmc
fi

exec 2>&1 > $SD_DIR/v3_init.log

echo "Installing..."

umount /etc
rm -rf /tmp/etc
cp -r /etc /tmp/

PASSWD_SHADOW="root::10933:0:99999:7:::"
echo $PASSWD_SHADOW >/tmp/etc/shadow

mount -o bind /tmp/etc /etc

echo "Enabling telnetd..."
telnetd

WYZEAPP_VER=$(grep -i AppVer /system/bin/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g')
if [ "$WYZEAPP_VER" != "4.36.0.228" ];then
    echo "Incorrect app version: $WYZEAPP_VER"
    /sbin/reboot
    exit 0
fi

if grep "wyze_hack.sh" /etc/init.d/rcS; then
    echo "Device already initialized"
    /sbin/reboot
    exit 0
fi

echo "Copying dummy wyze_hack.sh..."
cp $SCRIPT_DIR/wyze_hack.sh /configs/
chmod a+x /configs/wyze_hack.sh

sync
#kill -9 $(pidof pidof hl_client iCamera assis sysMonitor.sh kvs_stream)
#sysctl -w kernel.watchdog=0
#sysctl -a | grep watchdog

#echo "erase rootfs !!!!!!!!!!!"
#flash_eraseall /dev/mtd2
#sync
echo "write rootfs !!!!!!!!!!!"
flashcp -v $SCRIPT_DIR/rootfs.bin /dev/mtd2
sync

echo "done, rebooting..."
/sbin/reboot
