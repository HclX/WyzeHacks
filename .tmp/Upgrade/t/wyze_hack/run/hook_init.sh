#!/bin/sh
if [ "$DEVICE_MODEL" == "v3" ];then
    exit 0
fi

SYSTEM_DIR=$1
if [ -z "$SYSTEM_DIR" ];
then
    SYSTEM_DIR=/system
fi

if [ ! -f $WYZEHACK_BIN ];
then
    echo "wyze hack main binary not found: $WYZEHACK_BIN"
    exit 1
fi

if [ ! -f $WYZEHACK_CFG ];
then
    echo "wyze hack config file not found: $WYZEHACK_CFG"
    exit 1
fi

if [ ! -L $SYSTEM_DIR/init/app_init.sh ];
then
    cp $SYSTEM_DIR/init/app_init.sh $SYSTEM_DIR/init/app_init_orig.sh
fi

APP_INIT=`readlink $SYSTEM_DIR/init/app_init.sh`
if [ "$APP_INIT" != "$WYZEHACK_BIN" ];
then
    ln -s -f $WYZEHACK_BIN $SYSTEM_DIR/init/app_init.sh
fi
