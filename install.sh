#!/bin/sh
SCRIPT_DIR=`dirname $0`

# Clear update files to avoid update loop
rm /media/mmcblk0p1/version.ini.old
rm /media/mmcblk0p1/FIRMWARE_660R.bin.old
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old
mv /media/mmcblk0p1/FIRMWARE_660R.bin /media/mmcblk0p1/FIRMWARE_660R.bin.old

# Copying wyze_hack scripts
cp -r $SCRIPT_DIR/wyze_hack /system/bin/

# Updating user config if exists
if [ -f /media/mmcblk0p1/config.inc ];
then
    cp /media/mmcblk0p1/config.inc /system/bin/wyze_hack/
fi

/system/bin/wyze_hack/install.sh

echo "Done..."
