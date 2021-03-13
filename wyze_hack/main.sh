#!/bin/sh
[ -z $WYZEHACK_DBG ] || set -x

export WYZEHACK_DIR=$(dirname $(readlink -f $0))
export WYZEAPP_VER=$(grep -i AppVer /system/bin/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g')
export WYZEHACK_CFG=/configs/wyze_hack.cfg
export WYZEHACK_BIN=/configs/wyze_hack.sh

if grep "wyze_hack.sh" /etc/init.d/rcS; then
    export WYZEINIT_SCRIPT=/system/init/app_init.sh
else
    export WYZEINIT_SCRIPT=/system/init/app_init_orig.sh
fi

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
    export MMC_GPIO_REDIR="$WYZEHACK_DIR/mmc_gpio_value.txt"
    ;;

*)
    # Unknown
    export WYZEINIT_SCRIPT=/system/init/app_init.sh
    ;;
esac

# Hack vesion
source $WYZEHACK_DIR/hack_ver.inc

# User configuration
[ -f $WYZEHACK_CFG ] && source $WYZEHACK_CFG
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

play_sound() {
    echo "1">/sys/class/gpio/gpio${SPEAKER_GPIO}/value
    $WYZEHACK_DIR/bin/audioplay $@ 1>/dev/null 2>&1
    echo "0">/sys/class/gpio/gpio${SPEAKER_GPIO}/value
}

set_passwd() {
    /bin/umount /etc
    rm -rf /tmp/etc
    cp -r /etc /tmp/
    echo $1 >/tmp/etc/shadow
    /bin/mount -o bind /tmp/etc /etc
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

hook_init() {
    if grep "wyze_hack.sh" /etc/init.d/rcS; then
        echo "WyzeHack: hard modified, no need to hook ..."
        return 0
    fi

    if [ ! -f $WYZEHACK_BIN ];
    then
        echo "WyzeHack: wyze hack main binary not found: $WYZEHACK_BIN"
        return 1
    fi

    if [ ! -f $WYZEHACK_CFG ];
    then
        echo "WyzeHack: wyze hack config file not found: $WYZEHACK_CFG"
        return 1
    fi

    local SYSTEM_DIR=${1:-/system}
    if [ ! -L $SYSTEM_DIR/init/app_init.sh ];
    then
        echo "WyzeHack: backing up app_init.sh ..."
        cp $SYSTEM_DIR/init/app_init.sh $SYSTEM_DIR/init/app_init_orig.sh
    fi

    local APP_INIT=$(readlink $SYSTEM_DIR/init/app_init.sh)
    if [ "$APP_INIT" != "$WYZEHACK_BIN" ];
    then
        echo "WyzeHack: setting up symlink ..."
        ln -s -f $WYZEHACK_BIN $SYSTEM_DIR/init/app_init.sh
    fi

    ls -la $SYSTEM_DIR/init
    return 0
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
    
    if ! $LATEST_UPDATE/telnet_install.sh; then
        echo "WyzeHack: Failed to install update..."
        return 0
    fi

    echo "WyzeHack: Update installed."
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

check_uninstall() {
    if [ -f /media/mmc/wyzehacks/uninstall ]; then
        echo "WyzeHack: Uninstalling wyze hacks..."
        rm -f /media/mmc/wyzehacks/uninstall
        if cp $WYZEINIT_SCRIPT /system/init/app_init.sh;
        then
            rm -f $WYZEHACK_BIN
            rm -f $WYZEHACK_CFG
            echo "Uninstallation completed" > /media/mmc/wyzehacks/uninstall.done
            return 1
        else
            echo "Uninstallation failed" > /media/mmc/wyzehacks/uninstall.failed
        fi
    fi
    return 0
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
    $WYZEHACK_DIR/bin/hackutils mmc_insert

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

    if ! timeout -t $NFS_TIMEOUT df /media/mmcblk0p1 > /dev/null 2>&1;
    then
        echo "WyzeHack: NFS no longer mounted as /media/mmcblk0p1"
        return 1
    fi

    return 0
}

sys_monitor() {
    while true; do
        local REBOOT_FLAG=0
        if ! pgrep -f telnetd >/dev/null 2>&1; then
            echo "WyzeHack: Starting telnetd..."
            busybox telnetd
        fi

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

        if ! check_uninstall; then
            let REBOOT_FLAG=$REBOOT_FLAG+1
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
    killall sleep >/dev/null 2>&1
    sync
    sleep 10
    /sbin/reboot
}

cmd_reboot() {
    set -x
    echo "WyzeHack: Camera is rebooting in 10 seconds ..."
    if [ ! -z $IN_UPDATE ];
    then
        echo "WyzeHack: In update, checking system partition ..."
        cd /
        umount -f /system || echo "WyzeHack: umount system failed ..."
        mount -t jffs2 /dev/mtdblock4 /system || echo "WyzeHack: mount system failed ..."
    fi

    hook_init || echo "WyzeHack: hook_init failed ..."

    killall sleep >/dev/null 2>&1
    sync
    sleep 10
    /sbin/reboot $@
}

cmd_run() {
    # Run original script when no config file is found or unknown device model
    if [ ! -f "$WYZEHACK_CFG" ] || \
       [ -z "$DEVICE_MODEL" ]; then
        $WYZEINIT_SCRIPT &
        return 0
    fi

    # Run original script with reboot hook when device is in the middle of
    # upgrade
    if [ -f /system/.upgrade ] || \
       [ -f /configs/.upgrade ]; then
        export IN_UPDATE=1
        export PATH=$WYZEHACK_DIR/bin:$PATH
        export LD_LIBRARY_PATH=$WYZEHACK_DIR/bin:$LD_LIBRARY_PATH
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
    hostname ${HOSTNAME:-"WyzeCam-$(echo -n $DEVICE_ID | tail -c 4)"}

    if [ -z "$NFS_ROOT" ]; then
        # No NFS_ROOT specified, skipping all the MMC spoofing thing and run
        # original init script
        $WYZEINIT_SCRIPT&
    else
        # MMC detection hook init
        export PATH=$WYZEHACK_DIR/bin:$PATH
        export LD_LIBRARY_PATH=$WYZEHACK_DIR/bin:$LD_LIBRARY_PATH
        if [ ! -z $MMC_GPIO_REDIR ];then
            echo "1" > $MMC_GPIO_REDIR
        fi

        # libsetunbuf.so is used as LD_PRELOAD for later v2 firmwares, so
        # replace it with ours
        ln -s $WYZEHACK_DIR/bin/libhacks.so $WYZEHACK_DIR/bin/libsetunbuf.so
        $WYZEHACK_DIR/bin/hackutils init
        LD_PRELOAD=$WYZEHACK_DIR/bin/libhacks.so $WYZEINIT_SCRIPT &
    fi

    # Wait until WIFI is connected
    wait_wlan

    # This seems to be useful to prevent reboot caused by wifi dropping.
    if [ "$PING_KEEPALIVE" = "1" ];then
        GATEWAY_IP=`route -n | grep "UG" | awk -F' ' '{print $2}'`
        echo "WyzeHack: Trying to ping gateway $GATEWAY_IP..."
        ping $GATEWAY_IP 2>&1 >/dev/null &
    fi

    # Starting telnetd first
    busybox telnetd

    if [ -z "$NFS_ROOT" ]; then
        echo "WyzeHack: NFS_ROOT not defined, skipping NFS mount..."
    else
        if mount_nfs; then
            NFS_MOUNTED=1

            # Copy some information to the NFS share
            mkdir -p /media/mmcblk0p1/wyzehacks
            cp $WYZEHACK_CFG /media/mmcblk0p1/wyzehacks/config.inc

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

cmd_install() {
    set -x
    local SD_DIR=/media/mmcblk0p1
    if [ ! -d $SD_DIR ];
    then
        SD_DIR=/media/mmc
    fi

    if [ -d $SD_DIR ];
    then
        exec >$SD_DIR/install.log
        exec 2>&1
    fi

    echo "WyzeHack: Starting wyze hack installer..."

    play_sound $THIS_DIR/install_snd/begin.wav 50

    if [ -f $SD_DIR/debug/.copyfiles ];
    then
        echo "WyzeHack: Copying files for debugging purpose..."
        rm -rf $SD_DIR/debug/system
        rm -rf $SD_DIR/debug/etc

        # Copying system and etc back to SD card for analysis
        cp -rL /system $SD_DIR/debug
        cp -rL /etc $SD_DIR/debug
    fi

    if ! pgrep -f telnetd > /dev/null 2>&1; then
        # Swapping shadow file so we can telnetd in without password. This
        # is for debugging purpose.
        set_passwd 'root::10933:0:99999:7:::'

        # Always try to enable telnetd
        echo "WyzeHack: Enabling telnetd..."
        busybox telnetd
    fi

    if [ -z "$WYZEAPP_VER" ];
    then
        echo "WyzeHack: Wyze version not found!!!"
        play_sound $THIS_DIR/install_snd/failed.wav 50
        return 1
    fi

    echo "WyzeHack: Current Wyze software version is $WYZEAPP_VER"
    echo "WyzeHack: Installing WyzeHacks version $THIS_VER"

    # Updating user config if exists
    if [ -f "/params/wyze_hack.cfg" ];
    then
        echo "WyzeHack: Migrating from /params to /configs"
        cp /params/wyze_hack.cfg $WYZEHACK_CFG
        rm /params/wyze_hack.*
    fi

    if [ -f $THIS_DIR/config.inc ];
    then
        echo "WyzeHack: Use config file $THIS_DIR/config.inc"
        sed 's/\r$//' $THIS_DIR/config.inc > $WYZEHACK_CFG
    fi

    if [ -f "$SD_DIR/config.inc" ];
    then
        echo "WyzeHack: Use config file $SD_DIR/config.inc"
        sed 's/\r$//' $SD_DIR/config.inc > $WYZEHACK_CFG
    fi

    if [ ! -f "$WYZEHACK_CFG" ];
    then
        echo "WyzeHack: Configuration file not found, aborting..."
        play_sound $THIS_DIR/install_snd/failed.wav 50
        return 1
    fi

    if [ -z "$DEVICE_MODEL" ];
    then
        echo "WyzeHack: Unknown device model, aborting..."
        play_sound $THIS_DIR/install_snd/failed.wav 50
        return 1
    fi

    # Copying wyze_hack scripts
    echo "WyzeHack: Copying wyze hack binary..."
    cp $THIS_BIN $WYZEHACK_BIN

    # Hook app_init.sh
    echo "WyzeHack: Hooking up boot script..."
    if ! hook_init;
    then
        echo "WyzeHack: Hooking up boot script failed"
        play_sound $THIS_DIR/install_snd/failed.wav 50
        return 1
    fi

    play_sound $THIS_DIR/install_snd/finished.wav 50

    rm $SD_DIR/version.ini.old > /dev/null 2>&1	
    mv $SD_DIR/version.ini $SD_DIR/version.ini.old > /dev/null 2>&1
    /sbin/reboot
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
