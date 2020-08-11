#!/bin/sh
set -x

# Redirecting console logs to SD card
SD_DIR=/media/mmcblk0p1
if [ ! -d $SD_DIR ];
then
    SD_DIR=/media/mmc
fi

if [ -d $SD_DIR ];
then
    exec >$SD_DIR/install.log
    exec 2>&1
fi

echo "Starting wyze hack installer..."

$THIS_DIR/playwav.sh $THIS_DIR/snd/begin.wav 50

if [ -f $SD_DIR/debug/.copyfiles ];
then
    echo "Copying files for debugging purpose..."
    rm -rf $SD_DIR/debug/system
    rm -rf $SD_DIR/debug/etc

    # Copying system and etc back to SD card for analysis
    cp -rL /system $SD_DIR/debug
    cp -rL /etc $SD_DIR/debug
fi

# Always try to enable telnetd
echo "Enabling telnetd..."
echo 1>/configs/.Server_config
telnetd

# Swapping shadow file so we can telnetd in without password. This
# is for debugging purpose.
export PASSWD_SHADOW='root::10933:0:99999:7:::'
$THIS_DIR/bind_etc.sh

# Version check
source $THIS_DIR/app_ver.inc

if [ -z "$WYZEAPP_VER" ];
then
    echo "Wyze version not found!!!"
    $THIS_DIR/playwav.sh $THIS_DIR/snd/failed.wav 50
    exit 1
fi

echo "Current Wyze software version is $WYZEAPP_VER"
echo "Installing WyzeHacks version $THIS_VER"

# Updating user config if exists
if [ -f /tmp/Upgrade/config.inc ];
then
    echo "Use config file /tmp/Upgrade/config.inc"
    sed 's/\r$//' /tmp/Upgrade/config.inc > $WYZEHACK_CFG
fi

if [ -f $SD_DIR/config.inc ];
then
    echo "Use config file $SD_DIR/config.inc"
    sed 's/\r$//' $SD_DIR/config.inc > $WYZEHACK_CFG
fi

if [ ! -f $WYZEHACK_CFG ];
then
    echo "Configuration file not found, aborting..."
    $THIS_DIR/playwav.sh $THIS_DIR/snd/failed.wav 50
    exit 1
fi

# Copying wyze_hack scripts
echo "Copying wyze hack binary..."
cp $THIS_BIN $WYZEHACK_BIN

# Hook app_init.sh
echo "Hooking up boot script..."
if ! $THIS_DIR/hook_init.sh;
then
    echo "Hooking up boot script failed"
    $THIS_DIR/playwav.sh $THIS_DIR/snd/failed.wav 50
    exit 1
fi

$THIS_DIR/playwav.sh $THIS_DIR/snd/finished.wav 50

rm $SD_DIR/version.ini.old > /dev/null 2>&1	
mv $SD_DIR/version.ini $SD_DIR/version.ini.old > /dev/null 2>&1

reboot
