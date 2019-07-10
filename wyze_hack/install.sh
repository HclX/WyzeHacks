#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

# Enable telnetd
echo 1>/configs/.Server_config
telnetd

APP_VER=`grep -o "AppVer=.*$" /system/bin/app.ver | sed 's/AppVer=\(.*\)$/\1/g'`
if [ ! -f $SCRIPT_DIR/$APP_VER/app_init.sh ];
then
    echo "Unsupported version..."
    exit 1
fi

# Hook app_init.sh
if [ ! -f /system/init/app_init.sh.old ];
then
    cp /system/init/app_init.sh /system/init/app_init.sh.old
fi

cp $SCRIPT_DIR/$APP_VER/app_init.sh /system/init/app_init.sh
chmod a+x /system/init/app_init.sh
