#!/bin/sh
SCRIPT_DIR=`dirname $0`

# Clear update files to avoid update loop
rm /media/mmcblk0p1/version.ini.old
rm /media/mmcblk0p1/FIRMWARE_660R.bin.old
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old
mv /media/mmcblk0p1/FIRMWARE_660R.bin /media/mmcblk0p1/FIRMWARE_660R.bin.old

# Enable telnetd
echo 1>/configs/.Server_config
telnetd

# Copying wyze_hack scripts
cp -r $SCRIPT_DIR/wyze_hack /system/bin/

# Updating user config if exists
if [ -f /media/mmcblk0p1/config.inc ];
then
    cp /media/mmcblk0p1/config.inc /system/bin/wyze_hack/
fi

# Hook app_init.sh
if grep -q /system/bin/wyze_hack/run.sh /system/init/app_init.sh;
then
    # Already hooked, we are done.
    echo "Done..."
    exit 0
fi

cp /system/init/app_init.sh /system/init/app_init.sh.old
if ! grep -q /system/bin/iCamera /system/init/app_init.sh.old;
then
    echo "Unexpected, no iCamera command in app_init.sh"
    exit 1
fi

grep -v /system/bin/iCamera /system/init/app_init.sh.old > /system/init/app_init.sh
chmod a+x /system/init/app_init.sh
printf "\n/system/bin/wyze_hack/run.sh\n/system/bin/iCamera\n" >>/system/init/app_init.sh

cp /system/init/app_init.sh /media/mmcblk0p1/
echo "Done..."
