#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

tar -xf $SCRIPT_DIR/FIRMWARE_660R.bin -C /tmp/

if [ -f $SCRIPT_DIR/config.inc ];
then
    cp $SCRIPT_DIR/config.inc /tmp/Upgrade/
fi

/tmp/Upgrade/upgraderun.sh
