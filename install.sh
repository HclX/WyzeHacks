#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

# Clear update files to avoid update loop
rm /media/mmcblk0p1/version.ini.old
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old

# Copying system and etc back to SD card for analysis
mkdir -p /media/mmcblk0p1/target
cp -r /system /media/mmcblk0p1/target
cp -r /etc /media/mmcblk0p1/target

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
while true
do
	echo "Press [CTRL+C] to stop.."
	sleep 1
done

echo "Done..."
