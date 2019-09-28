#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

if [ ! -f "$SCRIPT_DIR/app_init.sh" ];
then
    echo "$SCRIPT_DIR/app_init.sh doesn't exist"
    exit 1
fi

if [ ! -L /system/init/app_init.sh ];
then
    cp /system/init/app_init.sh /system/init/app_init_orig.sh
fi

APP_INIT=`readlink /system/init/app_init.sh`
if [ "$APP_INIT" != $SCRIPT_DIR/app_init.sh ];
then
    ln -s -f $SCRIPT_DIR/app_init.sh /system/init/app_init.sh
fi
