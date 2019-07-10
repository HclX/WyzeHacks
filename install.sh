#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

# Clear update files to avoid update loop
rm /media/mmcblk0p1/version.ini.old
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old

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

/system/wyze_hack/install.sh

echo "Done..."
