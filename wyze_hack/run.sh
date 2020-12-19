#!/bin/sh
export WYZEHACK_MD5=$THIS_MD5
export WYZEHACK_DIR=$THIS_DIR
export WYZEHACK_VER=$THIS_VER

# User configuration
if [ -f $WYZEHACK_CFG ];
then
    source $WYZEHACK_CFG
    export PATH=$WYZEHACK_DIR/bin:$PATH
    export LD_LIBRARY_PATH=$WYZEHACK_DIR/bin:$LD_LIBRARY_PATH
else
    echo "Config file not found, clearing telnet password"
    export PASSWD_SHADOW='root::10933:0:99999:7:::'
fi

# Log syncing
if [ ! -z "$SYNC_BOOT_LOG" ];
then
    exec 2>&1 >> /tmp/boot.log
fi

# Set hostname
if [ -z "$HOSTNAME" ];then
    HOSTNAME="WyzeCam-"`echo -n $DEVICE_ID | tail -c 4`
fi
hostname $HOSTNAME

# Version check
WYZEAPP_VER="UNKNOWN"
source $WYZEHACK_DIR/app_ver.inc
export WYZEAPP_VER

if [ "$DEVICE_MODEL" == "v2" ];then
    export WYZEINIT_MD5=`md5sum /system/init/app_init_orig.sh | grep -oE "^[0-9a-f]*"`
else
    export WYZEINIT_MD5=`md5sum /system/init/app_init.sh | grep -oE "^[0-9a-f]*"`
fi

echo "WyzeApp version:  $WYZEAPP_VER"
echo "WyzeHack version: $WYZEHACK_VER"
echo "app_init signature: $WYZEINIT_MD5"

INIT_SCRIPT="$WYZEHACK_DIR/init/$WYZEINIT_MD5/init.sh"

if [ ! -f "$INIT_SCRIPT" ];
then
    echo "Unknown app_init.sh signature:$WYZEINIT_MD5"
    INIT_SCRIPT="$WYZEHACK_DIR/init/unknown/init.sh"
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
fi

# Load init script for the current firmware version
source $INIT_SCRIPT
