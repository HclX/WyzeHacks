#!/bin/sh
rm -rf /media/mmcblk0p1/debug
mkdir -p /media/mmcblk0p1/debug

exec >/media/mmcblk0p1/debug/install.log
exec 2>&1

SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

# Clear update files to avoid update loop
rm /media/mmcblk0p1/version.ini.old
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old

# Copying system and etc back to SD card for analysis
cp -rL /system /media/mmcblk0p1/debug
cp -rL /etc /media/mmcblk0p1/debug

# Copying wyze_hack scripts
cp -r $SCRIPT_DIR/wyze_hack /system/

# Updating user config if exists
if [ -f $SCRIPT_DIR/config.inc ];
then
    cp  $SCRIPT_DIR/config.inc /system/wyze_hack/config.inc
fi

if [ -f /media/mmcblk0p1/config.inc ];
then
    cp /media/mmcblk0p1/config.inc /system/wyze_hack/config.inc
fi

# Swapping shadow file so we can telnetd in without password. This
# is for debugging purpose.
export PASSWD_SHADOW='root::10933:0:99999:7:::'
$SCRIPT_DIR/wyze_hack/bind_etc.sh

# Installing the actual wyze hack scripts
/system/wyze_hack/install.sh

# Debugging ...
if [ -f /media/mmcblk0p1/no_reboot ];
then
    while true
    do
        echo "Press [CTRL+C] to stop.."
        sleep 1
    done
fi

echo "Done..."
