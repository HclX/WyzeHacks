#!/bin/sh

mkdaemon() {
    mkdir -p /var/log/$1
    # dmon options
    #   --stderr-redir  Redirects stderr to the log file as well
    #   --max-respawns  Sets the number of times dmon will restart a failed process
    #   --environ       Sets an environment variable. Used to remove buffering on stdout
    #
    # drlog options
    #   --max-size      The max size 1 log file can grow too
    #   --max-files     The number of logs that will exist at once
    #
    dmon \
      --stderr-redir \
      --max-respawns $2 \
      --environ "LD_PRELOAD=libsetunbuf.so" \
      /system/bin/$1 \
      -- drlog \
        --max-size 10k \
        --max-files 1 \
        /var/log/$1
}

chmod -R 755 /system

cd /tmp
if [ -f /system/.upgrade ]; then
    cd /backupa
    echo "init upgrading!!!!!!!!!!!!"
    sh ./upgrade.sh
    rm /system/.upgrade
fi

if [ -f /configs/.upgrade ]; then
    echo "new init upgrading!!!!!!!!!!!!"
    logfile=/configs/upgrade.log
    echo "sh /configs/merge_upgrade.sh ... "
    sh /configs/merge_upgrade.sh >> $logfile 2>&1 &
    exit 0
fi

# Update timestamp to something reasonable (the time this firmware was built)
CURRENT_EPOCH_TIME=$(date +%s)
FIRMWARE_BUILD_EPOCH_TIME=$(cat /system/init/firmware_build_epoch_time.txt)
FIRMWARE_BUILD_MINUS_ONE_DAY_EPOCH_TIME=$(($FIRMWARE_BUILD_EPOCH_TIME-86400))
# If "current time" < ("firmware build time" - "one day")
# Then update time to "firmware build time"
if [ "$CURRENT_EPOCH_TIME" -lt "$FIRMWARE_BUILD_MINUS_ONE_DAY_EPOCH_TIME" ]; then
    echo "Updating device time to:"
    date -s "@$FIRMWARE_BUILD_EPOCH_TIME"
fi

export LD_LIBRARY_PATH=/tmp:$LD_LIBRARY_PATH
echo "nameserver 8.8.8.8" >> /tmp/resolv.conf

echo "################################"
echo "######## this is dafang ########"
echo "################################"


insmod /driver/tx-isp.ko isp_clk=100000000
insmod /driver/exfat.ko
insmod /driver/sample_motor.ko
insmod /driver/sinfo.ko
insmod /driver/sample_pwm_core.ko
insmod /driver/sample_pwm_hal.ko
insmod /driver/audio.ko

if [ -f /driver/8189es.ko ]; then
    insmod /driver/8189es.ko
else
    insmod /driver/rtl8189ftv.ko
fi

echo 47 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio47/direction
echo 1 > /sys/class/gpio/gpio47/value

echo 61 > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio61/direction
echo 1 > /sys/class/gpio/gpio61/value
sleep 1
echo 0 > /sys/class/gpio/gpio61/value


#wpa_supplicant -Dwext -i wlan0 -c /system/etc/wpa_supplicant.conf -B
#udhcpc -i wlan0 -s /system/etc/udhcpc.script -q

#ifconfig eth0 up
#udhcpc -i eth0 -s /system/etc/udhcpc.script -q
ifconfig eth0 10.10.10.10 netmask 255.255.255.0
route add default gw 10.10.10.1

# Copy certificates into RAM, allowing it to be update
if [ -f /system/bin/cacert.pem ]; then
    cp /system/bin/cacert.pem /tmp/cacert.pem
else
    echo "WARNING!!! TLS Certs not found at /system/bin/cacert.pem"
    echo "           ALL HTTPS TRAFFIC EXPECTED TO FAIL"
fi

# open ircut
#cp /system/bin/setir /tmp/
#config ip address

###/system/bin/carrier-server --st=imx322
###/system/bin/singleBoadTest
/system/bin/test_UP &
/system/bin/sdkshellcalltool &
/system/bin/hl_client &
/system/bin/iCamera &
/system/bin/dongle_app &
/system/bin/sinker &

for i in $(seq 1 2)
do
    sleep 10
    pidof iCamera > /dev/null
    if pidof iCamera > /dev/null; then
        echo "iCamera is Running"
        exit
    fi
done

echo "iCamera not running"
echo "restore system from backup"
touch /configs/.upgrade
touch /configs/.fsrepair

sleep 1
reboot
