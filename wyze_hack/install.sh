#!/bin/sh
SCRIPT_DIR=`dirname $0`

# Enable telnetd
echo 1>/configs/.Server_config
telnetd

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

printf "exec >>/tmp/boot0.log\nexec 2>&1\n" >/system/init/app_init.sh.new
grep -v /system/bin/iCamera /system/init/app_init.sh.old >> /system/init/app_init.sh.new
printf "\n/system/bin/wyze_hack/run.sh\n/system/bin/iCamera\n" >>/system/init/app_init.sh.new
chmod a+x /system/init/app_init.sh.new

cp /system/init/app_init.sh.new /system/init/app_init.sh
cp /system/init/app_init.sh /media/mmcblk0p1/
