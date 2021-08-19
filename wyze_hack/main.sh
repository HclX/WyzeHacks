#!/bin/sh
[ -z $WYZEHACK_DBG ] || set -x

export THIS_DIR=$(dirname $(readlink -f $0))
export WYZEAPP_VER=$(grep -i AppVer /system/bin/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g')
export WYZEHACK_CFG=$WYZEHACK_DIR/wyze_hack.cfg
export WYZEINIT_SCRIPT=/system/init/app_init.sh

case $WYZEAPP_VER in
3.9.*)
    # Cam V1
    export DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')
    export DEVICE_MODEL="V1"
    export SPEAKER_GPIO=63
    ;;

4.9.*)
    # Cam V2
    export DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')
    export DEVICE_MODEL="V2"
    export SPEAKER_GPIO=63
    ;;

4.28.*)
    # Cam V2 RTSP
    export DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')
    export DEVICE_MODEL="V2"
    export SPEAKER_GPIO=63
    ;;

4.10.*)
    # Cam PAN
    export DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')
    export DEVICE_MODEL="PAN"
    export SPEAKER_GPIO=63
    ;;

4.29.*)
    # Cam PAN RTSP
    export DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')
    export DEVICE_MODEL="PAN"
    export SPEAKER_GPIO=63
    ;;

4.25.*)
    # Doorbell
    export DEVICE_ID=$(grep -E -o CONFIG_INFO=[0-9A-F]+ /params/config/.product_config | cut -c 13-24)
    export DEVICE_MODEL="DB"
    export SPEAKER_GPIO=63
    ;;

4.36.*)
    # Cam V3
    export DEVICE_ID=$(grep -E -o CONFIG_INFO=[0-9A-F]+ /configs/.product_config | cut -c 13-24)
    export DEVICE_MODEL="V3"
    export SPEAKER_GPIO=63
    export MMC_GPIO_REDIR="$THIS_DIR/mmc_gpio_value.txt"
    ;;

*)
    # Unknown
    ;;
esac

# Hack vesion
. $THIS_DIR/hack_ver.inc

# User configuration
if [ -f $WYZEHACK_CFG ]; then
    sed 's/\r$//' $WYZEHACK_CFG > $THIS_DIR/wyze_hack.cfg
    . $THIS_DIR/wyze_hack.cfg
fi

[ -z $WYZEHACK_DBG ] || set -x

# Default values
export NFS_TIMEOUT="${NFS_TIMEOUT:-15}"
export NFS_OPTIONS="${NFS_OPTIONS:--o nolock,rw,noatime,nodiratime}"
export UPDATE_DIR="${UPDATE_DIR:-/mnt/WyzeCams/wyzehacks}"

# These features rely on NFS
if [ -z "$NFS_ROOT" ]; then
    export ARCHIVE_OLDER_THAN=
    export SYNC_BOOT_LOG=
    export AUTO_UPDATE=
    export AUTO_CONFIG=
fi

on_reboot() {
    echo "!!!SYSTEM REBOOTING!!!"
    TS=$(date +"%Y_%m_%d_%H%M%S")

    cp /tmp/boot.log $WYZEHACK_DIR/reboot_$TS.log
    sync
    umount -f $WYZEHACK_DIR

    cp /tmp/boot.log $LOG_DIR/reboot_$TS.log
    sync
    umount -f $WYZEHACK_DIR
}

trap on_reboot TERM

play_sound() {
    echo "1">/sys/class/gpio/gpio${SPEAKER_GPIO}/value
    $THIS_DIR/bin/audioplay $@ 1>/dev/null 2>&1
    echo "0">/sys/class/gpio/gpio${SPEAKER_GPIO}/value
}

set_passwd() {
    /bin/umount /etc/shadow
    echo $1 >/tmp/shadow
    /bin/mount -o bind /tmp/shadow /etc/shadow
}

wait_wlan() {
    while true
    do
        if  ifconfig wlan0 | grep "inet addr";
        then
            break
        fi

        echo "WyzeHack: wlan0 not ready yet..."
        sleep 10
    done
}

log_init() {
    LOG_CNT=0
    LOG_DIR=/media/mmcblk0p1/wyzehacks/log
    mkdir -p $LOG_DIR

    if [ -z "$SYNC_BOOT_LOG" ];
    then
        # This is to record device reboot time when log sync is not enabled
        LOG_CNT=$(ls $LOG_DIR/reboot_* | wc -l)
        let LOG_CNT=$LOG_CNT+1
        touch $LOG_DIR/reboot_$LOG_CNT
        return
    fi

    # Wait until the NTP client updated local time, so we can have correct log
    # timestamp
    touch $LOG_DIR/.timestamp
    while true
    do
        sleep 5
        touch /tmp/.timestamp
        if [ /tmp/.timestamp -ot $LOG_DIR/.timestamp ];
        then
            echo "WyzeHack: Waiting for system clock sync..."
            continue
        fi

        break
    done

    LOG_TS=$(date +"%Y_%m_%d_%H%M%S")
}

log_sync() {
    local LOGSIZE=$(wc /tmp/boot.log -c| awk '{print $1}')
    if [ "$LOGSIZE" -gt "1000000" ];
    then
        kill -9 $LOG_TAIL_PID
        unset LOG_TAIL_PID
        cp /tmp/boot.log /tmp/boot1.log
        echo "WyzeHack: Log truncated" > /tmp/boot.log
    fi

    if [ -z "$LOG_TAIL_PID" ];
    then
        tail -n +0 -f /tmp/boot.log > $LOG_DIR/boot_${LOG_TS}_${LOG_CNT}.log 2>&1 &
        LOG_TAIL_PID=$!
        let LOG_CNT=$LOG_CNT+1
    fi
}

do_archive() {
    mkdir -p /media/mmcblk0p1/archive/record
    mkdir -p /media/mmcblk0p1/archive/alarm

    for DAY in $(ls -d /media/mmcblk0p1/record/???????? 2>/dev/null| sort | head -n -$ARCHIVE_OLDER_THAN 2>/dev/null| grep -oE "[0-9]{8}$");
    do
        local SRC_DIR=/media/mmcblk0p1/record/$DAY
        local DST_DIR=/media/mmcblk0p1/archive/record/$DAY

        if [ ! -d $SRC_DIR ];
        then
            continue
        fi

        for SRC_FILE in $(find "$SRC_DIR" -name *.mp4 2>/dev/null| grep -oE "[0-9]{2}/[0-9]{2}\.mp4$");
        do
            local DST_FILE=$(echo "${DAY}_${SRC_FILE}" | sed 's,/,_,g')
            if [ ! -d $DST_DIR ];
            then
                mkdir -p $DST_DIR
            fi

            mv -n $SRC_DIR/$SRC_FILE $DST_DIR/$DST_FILE
        done
        rmdir $SRC_DIR/* $SRC_DIR
    done

    for DAY in $(ls -d /media/mmcblk0p1/alarm/???????? 2>/dev/null| sort | head -n -$ARCHIVE_OLDER_THAN 2>/dev/null| grep -oE "[0-9]{8}$");
    do
        local SRC_DIR=/media/mmcblk0p1/alarm/$DAY
        local DST_DIR=/media/mmcblk0p1/archive/alarm/$DAY

        mv -n $SRC_DIR $DST_DIR
    done
}

check_config() {
    if [ ! -f "/media/mmc/wyzehacks/config.new" ];then
        echo "WyzeHack: New config file not found, skipping..."
        return 0
    fi

    echo "WyzeHack: Found new config file, checking..."
    sed 's/\r$//' /media/mmc/wyzehacks/config.new > /tmp/tmp_config
    echo "WyzeHack: New config content:"
    echo "WyzeHack: ====================="
    cat /tmp/tmp_config
    echo "WyzeHack: ====================="

    echo "WyzeHack: Applying new config"
    cp /tmp/tmp_config $WYZEHACK_CFG
    rm /media/mmc/wyzehacks/config.new
    return 1
}

check_update() {
    echo "WyzeHack: AUTO_UPDATE enabled, checking for update in $UPDATE_DIR..."
    local LATEST_UPDATE=$(ls -d $UPDATE_DIR/release_?_?_?? | sort -r | head -1)
    if [ -z "$LATEST_UPDATE" ]; then
        echo "WyzeHack: Found no updates, skipping..."
        return 0
    fi

    echo "WyzeHack: Found update $LATEST_UPDATE, checking..."
    local UPDATE_FLAG=$LATEST_UPDATE/${DEVICE_ID}.done
    if [ -f "$UPDATE_FLAG" ]; then
        echo "WyzeHack: Update $LATEST_UPDATE already installed, skipping..."
        return 0
    fi

    echo "WyzeHack: Installing update from $LATEST_UPDATE..."
    touch $UPDATE_FLAG

    if ! cp $LATEST_UPDATE/wyze_hack/wyze_hack.bin $WYZEHACK_BIN; then
        echo "WyzeHack: Copying $LATEST_UPDATE/wyze_hack/wyze_hack.bin to $WYZEHACK_BIN failed."
        return 0
    fi

    echo "WyzeHack: done, reboot..."
    return 1
}

check_reboot() {
    # Unfortunately we don't have cron job or at command in this environment, so use
    # a poorman's implementation
    local CUR_TIME=$(date +"%H:%M")
    if [ "$CUR_TIME" = "$REBOOT_AT" ];
    then
        return 1
    else
        return 0
    fi
}

mount_nfs() {
    local NFS_MOUNT="/bin/mount $NFS_OPTIONS"
    local RETRY_COUNT=0
    while true
    do
        # We will try mount the NFS for 10 times, and fail if still not available
        let RETRY_COUNT=$RETRY_COUNT+1
        if [ $RETRY_COUNT -gt 100 ]; then
            return 1
        fi

        if ! /bin/mount | grep -q "$NFS_ROOT on /mnt";
        then
            echo "WyzeHack: $NFS_ROOT not mounted, try mounting to /mnt..."
            if ! $NFS_MOUNT $NFS_ROOT /mnt;
            then
                echo "WyzeHack: [$NFS_MOUNT $NFS_ROOT /mnt] failed, will retry..."
                sleep 10
                continue
            fi
        fi

        local CAM_DIR=/mnt/WyzeCams/$DEVICE_ID
        for DIR in /mnt/WyzeCams/*/;
        do
            if [ -f "$DIR/.mac_$DEVICE_ID" ];
            then
                CAM_DIR="$DIR"
                break
            fi
        done

        echo "WyzeHack: Mounting directory $CAM_DIR as SD card"
        if [ ! -d "$CAM_DIR" ];
        then
            echo "WyzeHack: Creating data directory [$CAM_DIR]"
            if ! mkdir -p "$CAM_DIR";
            then
                echo "WyzeHack: [mkdir -p $CAM_DIR] failed, will retry..."
                sleep 1
                continue
            fi
        fi

        echo "WyzeHack: Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmcblk0p1"
        mkdir -p /media/mmcblk0p1
        if ! mount -o bind "$CAM_DIR" /media/mmcblk0p1;
        then
            echo "WyzeHack: mount $CAM_DIR as /media/mmcblk0p1 failed, will retry..."
            sleep 5
            continue
        fi

        echo "WyzeHack: Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmc"
        mkdir -p /media/mmc
        if ! mount -o bind "$CAM_DIR" /media/mmc;
        then
            echo "WyzeHack: mount $CAM_DIR as /media/mmc failed, will retry..."
            sleep 5
            continue
        fi

        break
    done

    echo "WyzeHack: Notifying iCamera about SD card insertion event..."
    if [ ! -z $MMC_GPIO_REDIR ]; then
        echo "0" > $MMC_GPIO_REDIR
    fi
    $THIS_DIR/bin/hackutils mmc_insert

    # Mark this directory for this camera
    touch /media/mmcblk0p1/.mac_$DEVICE_ID

    return 0
}

# Detecting NFS share mount failure
check_nfs() {
    /bin/mount > /tmp/mount.txt
    if ! grep "/media/mmcblk0p1 type nfs" /tmp/mount.txt > /dev/null 2>&1;
    then
        echo "WyzeHack: NFS no longer mounted as /media/mmcblk0p1"
        return 1
    fi

    if ! grep "/media/mmc type nfs" /tmp/mount.txt > /dev/null 2>&1;
    then
        echo "WyzeHack: NFS no longer mounted as /media/mmc"
        return 1
    fi

    # A new version BusyBox changed the command line format of timeout, causing
    # lots of false alarms.
    if timeout --help 2>&1| grep -F '[-t SECS]' > /dev/null; then
        TIMEOUT_ARGS="-t $NFS_TIMEOUT"
    else
        TIMEOUT_ARGS="$NFS_TIMEOUT"
    fi

    if ! timeout $TIMEOUT_ARGS ls /media/mmcblk0p1 > /dev/null 2>&1;
    then
        echo "WyzeHack: NFS no longer mounted as /media/mmcblk0p1"
        return 1
    fi

    return 0
}

# Starting sshd
check_sshd() {
    if pgrep -f dropbear >/dev/null 2>&1; then
        return 0
    fi

    echo "WyzeHack: Starting ssh daemon..."
    DROPBEAR_BIN=$THIS_DIR/bin/dropbear
    HOST_KEY_FILE=$WYZEHACK_DIR/config/dropbear_ecdsa_host_key
    if [ ! -f $HOST_KEY_FILE ]; then
        echo "WyzeHack: Generating SSH host key file $HOST_KEY_FILE"
        mkdir -p $WYZEHACK_DIR/config
        $THIS_DIR/bin/dropbearkey -t ecdsa -f $HOST_KEY_FILE
    fi
    $DROPBEAR_BIN -B -r $HOST_KEY_FILE
}

sys_monitor() {
    while true; do
        local REBOOT_FLAG=0

        check_sshd

        if [ ! -z "$ARCHIVE_OLDER_THAN" ]; then
            do_archive
        fi

        if [ "$SYNC_BOOT_LOG" = "1" ]; then
            if pidof syslogd > /dev/null 2>&1 && \
               ! pidof logread > /dev/null 2>&1 ; then
                logread
                logread -f &
            fi
            log_sync
        fi

        if [ "$AUTO_UPDATE" = "1" ]; then
            check_update
            let REBOOT_FLAG=$REBOOT_FLAG+$?
        fi

        if [ "$AUTO_CONFIG" = "1" ]; then
            check_config
            let REBOOT_FLAG=$REBOOT_FLAG+$?
        fi

        if [ ! -z "$REBOOT_AT" ]; then
            check_reboot
            let REBOOT_FLAG=$REBOOT_FLAG+$?
        fi

        if [ ! -z "$NFS_MOUNTED" ]; then
            ifconfig > /media/mmcblk0p1/ifconfig.txt 2>&1
            if ! check_nfs; then
                if [ ! -z "$NOTIFICATION_VOLUME" ];
                then
                    play_sound /usr/share/notify/CN/user_need_check.wav $NOTIFICATION_VOLUME
                fi
                let REBOOT_FLAG=$REBOOT_FLAG+1
            fi
        fi

        if [ "$REBOOT_FLAG" != "0" ];then
            break
        fi

        sleep 60
    done

    echo "WyzeHack: Rebooting..."
    on_reboot

    killall sleep >/dev/null 2>&1
    sync
    sleep 10
    /sbin/reboot
}

cmd_run() {
    # Run original script when no config file is found or unknown device model
    if [ ! -f "$WYZEHACK_CFG" ] || \
       [ -z "$DEVICE_MODEL" ] || \
       [ -f /system/.upgrade ] || \
       [ -f /configs/.upgrade ] ; then
        $WYZEINIT_SCRIPT &
        return 0
    fi

    # Log syncing
    if [ ! -z "$SYNC_BOOT_LOG" ]; then
        exec >> /tmp/boot.log 2>&1
    fi

    # Customize password
    if [ ! -z "$PASSWD_SHADOW" ]; then
        set_passwd $PASSWD_SHADOW
    fi

    echo "WyzeHack: WyzeApp version:  $WYZEAPP_VER"
    echo "WyzeHack: WyzeHack version: $WYZEHACK_VER"

    # Set hostname
    if [ -z "${CUSTOM_HOSTNAME}" ]; then
        CUSTOM_HOSTNAME="WyzeCam${DEVICE_MODEL}-$(echo -n $DEVICE_ID | tail -c 4)"
    fi
    hostname ${CUSTOM_HOSTNAME}

    if [ -z "$NFS_ROOT" ]; then
        # No NFS_ROOT specified, skipping all the MMC spoofing thing and run
        # original init script
        $WYZEINIT_SCRIPT&
    else
        # MMC detection hook init
        export PATH=$THIS_DIR/bin:$PATH
        export LD_LIBRARY_PATH=$THIS_DIR/bin:$LD_LIBRARY_PATH
        if [ ! -z $MMC_GPIO_REDIR ];then
            echo "1" > $MMC_GPIO_REDIR
        fi

        # libsetunbuf.so is used as LD_PRELOAD for later v2 firmwares, so
        # replace it with ours
        mount -o bind $THIS_DIR/bin/libhacks.so /system/lib/libsetunbuf.so
        $THIS_DIR/bin/hackutils init
        LD_PRELOAD=$THIS_DIR/bin/libhacks.so $WYZEINIT_SCRIPT &
    fi

    # Wait until WIFI is connected
    wait_wlan

    # This seems to be useful to prevent reboot caused by wifi dropping.
    if [ "$PING_KEEPALIVE" = "1" ];then
        GATEWAY_IP=`route -n | grep "UG" | awk -F' ' '{print $2}'`
        echo "WyzeHack: Trying to ping gateway $GATEWAY_IP..."
        ping $GATEWAY_IP 2>&1 >/dev/null &
    fi

    # Starting sshd first
    check_sshd

    if [ -z "$NFS_ROOT" ]; then
        echo "WyzeHack: NFS_ROOT not defined, skipping NFS mount..."
    else
        if mount_nfs; then
            NFS_MOUNTED=1

            # Copy some information to the NFS share
            mkdir -p /media/mmcblk0p1/wyzehacks
            cp $WYZEHACK_CFG /media/mmcblk0p1/wyzehacks/wyze_hack.cfg

            # Initializing logging
            log_init
        else
            echo "WyzeHack: NFS mount failed, rebooting..."
            /sbin/reboot
        fi
    fi

    # Custom script
    if [ -f "$CUSTOM_SCRIPT" ]; then
        echo "WyzeHack: Starting custom script: $CUSTOM_SCRIPT"
        $CUSTOM_SCRIPT &
    else
        echo "WyzeHack: Custom script not found: $CUSTOM_SCRIPT"
    fi

    sys_monitor
}

cmd_test() {
    echo "WyzeHack: test: args=$@"
}

ACTION="cmd_${0##*/}"
if [ "$ACTION" = "cmd_main.sh" ];
then
    ACTION="cmd_${1:-run}"
    [ "$#" -gt 1 ] && shift
fi

$ACTION $@
