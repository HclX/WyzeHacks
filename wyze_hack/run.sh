#!/bin/sh
export WYZEHACK_MD5=$THIS_MD5
export WYZEHACK_DIR=$THIS_DIR
export WYZEHACK_VER=$THIS_VER

# Version check
WYZEAPP_VER="UNKNOWN"
source $WYZEHACK_DIR/app_ver.inc

echo "WyzeApp version:  $WYZEAPP_VER"
echo "WyzeHack version: $WYZEHACK_VER"

# User configuration
if [ -f $WYZEHACK_CFG ];
then

    source $WYZEHACK_CFG
    export PATH=$WYZEHACK_DIR/bin:$PATH
else
    echo "Config file not found, clearing telnet password"
    export PASSWD_SHADOW='root::10933:0:99999:7:::'
fi

if [ ! -z "$SYNC_BOOT_LOG" ];
then
    exec 2>&1 >> /tmp/boot.log
fi

# Special handling for updates
if [ -f /system/.upgrade ] || [ -f /configs/.upgrade ];
then
    UPDATE_PENDING=1
fi

if [ -z "$UPDATE_PENDING" ] && [ -f $WYZEHACK_CFG ];
then
    $WYZEHACK_DIR/bind_etc.sh
    $WYZEHACK_DIR/mount_nfs.sh & 
    [ -x "/params/custom.sh" ] && { /params/custom.sh & }
fi

LD_PRELOAD=$WYZEHACK_DIR/bin/libhacks.so /system/init/app_init_orig.sh
