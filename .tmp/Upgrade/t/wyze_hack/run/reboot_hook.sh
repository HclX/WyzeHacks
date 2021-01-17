#!/bin/sh
echo "Camera is rebooting in 10 seconds ..."
if [ ! -f /system/.system ];
then
    echo "System partition not mounted, mounting..."
    mount -t jffs2 /dev/mtdblock4 /system
fi

$WYZEHACK_DIR/hook_init.sh
$WYZEHACK_DIR/auto_update.sh
$WYZEHACK_DIR/auto_config.sh

killall sleep
sync
sleep 10
