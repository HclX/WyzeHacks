#!/bin/sh

# Set mdev
echo /sbin/mdev > /proc/sys/kernel/hotplug
/sbin/mdev -s && echo "mdev is ok......"

echo " __________________________________
|                                  |
|                                  |
|                                  |
|                                  |
| _   _             _           _  |
|| | | |_   _  __ _| |     __ _(_) |
|| |_| | | | |/ _| | |  _ / _| | | |
||  _  | |_| | (_| | |_| | (_| | | |
||_| |_|\__,_|\__,_|_____|\__,_|_| |
|                                  |
|                                  |
|_____2020_WYZE_CAM_V3_@HUALAI_____|
"

# create console and null node for nfsroot
#mknod -m 600 /dev/console c 5 1
#mknod -m 666 /dev/null c 1 3

# Set Global Environment
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH=/system/bin:$PATH
export LD_LIBRARY_PATH=/system/lib
export LD_LIBRARY_PATH=/thirdlib:$LD_LIBRARY_PATH

# networking
ifconfig lo up
#ifconfig eth0 192.168.1.80

# Set the system time from the hardware clock
#hwclock -s

# Mount driver partition
mount -t squashfs /dev/mtdblock3 /system

# Mount configs partition
mount -t jffs2 /dev/mtdblock6 /configs

# Run init script
if [ -f /configs/wyze_hack.sh ]; then
    /configs/wyze_hack.sh &
elif [ -f /system/init/app_init.sh ]; then
    /system/init/app_init.sh &
fi

# Run liteOta upgrade app
#/liteOta &
