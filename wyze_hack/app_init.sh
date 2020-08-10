#!/bin/sh
echo "WyzeApp version:  $WYZEAPP_VER"
echo "WyzeHack version: $WYZEHACK_VER"

# Special handling for updates
if [ -f /system/.upgrade ] || [ -f /configs/.upgrade ];
then
    UPDATE_PENDING=1
fi

if [ -z "$UPDATE_PENDING" ] && [ -f $WYZEHACK_CFG ];
then
    $WYZEHACK_DIR/bind_etc.sh
    $WYZEHACK_DIR/mount_nfs.sh & 
fi

LD_PRELOAD=$WYZEHACK_DIR/bin/libhacks.so /system/init/app_init_orig.sh
