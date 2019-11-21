#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

$SCRIPT_DIR/wyze_hack/playwav.sh $SCRIPT_DIR/wyze_hack/snd/start.wav 80

# debugging
if [ -d /media/mmcblk0p1/debug/ ];
then
    # Redirecting console logs to SD card
    exec >/media/mmcblk0p1/debug/install.log
    exec 2>&1
fi

if [ -f /media/mmcblk0p1/debug/.copyfiles ];
then
    rm -rf /media/mmcblk0p1/debug/system
    rm -rf /media/mmcblk0p1/debug/etc

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
source $SCRIPT_DIR/wyze_hack/app_ver.inc
source $SCRIPT_DIR/wyze_hack/hack_ver.inc

if [ -z "$WYZEAPP_VER" ];
then
    echo "Wyze version not found!!!"
    exit 1
fi

echo "Current Wyze software version is $WYZEAPP_VER"
echo "Installing WyzeHacks version $WYZEHACK_VER"

# Clear update files to avoid update loop
rm /media/mmcblk0p1/version.ini.old
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old

# Copying wyze_hack scripts
WYZEHACK_DIR=/system/wyze_hack
cp $WYZEHACK_DIR/config.inc /tmp/config.inc
rm -rf $WYZEHACK_DIR
cp -r $SCRIPT_DIR/wyze_hack $WYZEHACK_DIR
cp /tmp/config.inc $WYZEHACK_DIR/

# Updating user config if exists
if [ -f $SCRIPT_DIR/config.inc ];
then
    cp  $SCRIPT_DIR/config.inc $WYZEHACK_DIR/
fi

if [ -f /media/mmcblk0p1/config.inc ];
then
    cp /media/mmcblk0p1/config.inc $WYZEHACK_DIR/
fi

# Hook app_init.sh
$WYZEHACK_DIR/hookup.sh

$SCRIPT_DIR/wyze_hack/playwav.sh $SCRIPT_DIR/wyze_hack/snd/done.wav 80

# Debugging ...
if [ -f /media/mmcblk0p1/debug/.noreboot ];
then
    while true
    do
        echo "Press [CTRL+C] to stop.."
        sleep 1
    done
fi

echo "Done..."
