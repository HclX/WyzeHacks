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

if [ -z "$SYNC_BOOT_LOG" ];
then
    $WYZEHACK_DIR/app_init.sh
else
    $WYZEHACK_DIR/app_init.sh >> /tmp/boot.log 2>&1
fi
