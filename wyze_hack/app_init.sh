#!/bin/sh
exec >>/tmp/boot.log
exec 2>&1

WYZEHACK_DIR=/system/wyze_hack

# Version check
WYZEAPP_VER="UNKNOWN"
WYZEHACK_VER="UNKNOWN"

if [ -f $WYZEHACK_DIR/app_ver.inc ];
then
    source $WYZEHACK_DIR/app_ver.inc
fi

if [ -f $WYZEHACK_DIR/hack_ver.inc ];
then
    source $WYZEHACK_DIR/hack_ver.inc
fi

echo "WyzeApp version:  $WYZEAPP_VER"
echo "WyzeHack version: $WYZEHACK_VER"

# User configuration
if [ -f $WYZEHACK_DIR/config.inc ];
then
    source $WYZEHACK_DIR/config.inc
    export PATH=$WYZEHACK_DIR/bin:$PATH
else
    echo "Config file not found, clearing telnet password"
    export PASSWD_SHADOW='root::10933:0:99999:7:::'
fi

$WYZEHACK_DIR/bind_etc.sh
$WYZEHACK_DIR/mount_nfs.sh &

/system/init/app_init_orig.sh
