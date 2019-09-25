#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

# debugging
if [ -d /media/mmcblk0p1/debug ];
then
    rm -rf /media/mmcblk0p1/debug/*

    # Redirecting console logs to SD card
    exec >/media/mmcblk0p1/debug/install.log
    exec 2>&1

    # Copying system and etc back to SD card for analysis
    cp -rL /system /media/mmcblk0p1/debug
    cp -rL /etc /media/mmcblk0p1/debug
fi

# Always try to enable telnetd
echo 1>/configs/.Server_config

# Swapping shadow file so we can telnetd in without password. This
# is for debugging purpose.
export PASSWD_SHADOW='root::10933:0:99999:7:::'
$SCRIPT_DIR/wyze_hack/bind_etc.sh

# Version check
WYZE_VER=`grep AppVer /system/bin/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g'`
if [ -z "$WYZE_VER" ];
then
    echo "Wyze version not found!!!"
    exit 1
fi

echo "Current Wyze software version is $WYZE_VER"
if [ ! -d $SCRIPT_DIR/wyze_hack/$WYZE_VER ];
then
    echo "Wyze version $WYZE_VER not supported!!!"
    exit 1
fi

source $SCRIPT_DIR/wyze_hack/ver.inc
echo "Installing WyzeHacks version $SCRIPT_VER"

# Clear update files to avoid update loop
rm /media/mmcblk0p1/version.ini.old
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old

# Copying wyze_hack scripts
cp -r $SCRIPT_DIR/wyze_hack /system/wyze_hack_$SCRIPT_VER

# Updating user config if exists
if [ -f $SCRIPT_DIR/config.inc ];
then
    cp  $SCRIPT_DIR/config.inc /system/wyze_hack_$SCRIPT_VER/
fi

if [ -f /media/mmcblk0p1/config.inc ];
then
    cp /media/mmcblk0p1/config.inc /system/wyze_hack_$SCRIPT_VER/
fi

if [ -f /system/wyze_hack/config.inc ];
then
    cp /system/wyze_hack/config.inc /system/wyze_hack_$SCRIPT_VER/
fi

# Hook app_init.sh
cp -r $SCRIPT_DIR/wyze_hack/$WYZE_VER/* /system/init/
chmod a+x /system/init/app_init.sh

# Swapping the installation
rm -rf /system/wyze_hack
ln -s /system/wyze_hack_$SCRIPT_VER /system/wyze_hack

# Debugging ...
if [ -f /media/mmcblk0p1/.noreboot ];
then
    while true
    do
        echo "Press [CTRL+C] to stop.."
        sleep 1
    done
fi

echo "Done..."
