#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

OLD_WYZEHACKS_DIR=/system/wyze_hack

tar -xf $SCRIPT_DIR/FIRMWARE_660R.bin -C /tmp/

if [ -f $OLD_WYZEHACKS_DIR/config.inc ];
then
    cp $OLD_WYZEHACKS_DIR/config.inc /tmp/Upgrade/
fi

if [ -f $SCRIPT_DIR/config.inc ];
then
    cp $SCRIPT_DIR/config.inc /tmp/Upgrade/
fi

/tmp/Upgrade/upgraderun.sh
