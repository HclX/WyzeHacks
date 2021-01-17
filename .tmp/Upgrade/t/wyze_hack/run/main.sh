#!/bin/sh
WYZEHACK_DIR=$(dirname $(readlink -f $0))
WYZEAPP_VER=$(grep -i AppVer /system/bin/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g')
case $WYZEAPP_VER in
4.9.*)
    WYZEHACK_CFG=/params/wyze_hack.cfg
    WYZEHACK_BIN=/params/wyze_hack.sh
    WYZEINIT_MD5=$(md5sum /system/init/app_init_orig.sh | grep -oE "^[0-9a-f]*")
    DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')
    DEVICE_MODEL="V2"
    SPEAKER_GPIO=63
    ;;

4.10.*)
    WYZEHACK_CFG=/params/wyze_hack.cfg
    WYZEHACK_BIN=/params/wyze_hack.sh
    WYZEINIT_MD5=$(md5sum /system/init/app_init_orig.sh | grep -oE "^[0-9a-f]*")
    DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')
    DEVICE_MODEL="PAN"
    SPEAKER_GPIO=63
    ;;

4.36.*)
    WYZEHACK_CFG=/configs/wyze_hack.cfg
    WYZEHACK_BIN=/configs/wyze_hack.sh
    WYZEINIT_MD5=$(md5sum /system/init/app_init.sh | grep -oE "^[0-9a-f]*")
    DEVICE_ID=$(grep -E -o CONFIG_INFO=[0-9A-F]+ /configs/.product_config | cut -c 13-24)
    DEVICE_MODEL="V3"
    SPEAKER_GPIO=63
    ;;
esac

# Unsupported device model
[ -z $DEVICE_MODEL ] && exit 1

# Hack vesion
source $WYZEHACK_DIR/hack_ver.inc

# User configuration
[ -f $WYZEHACK_CFG ] && source $WYZEHACK_CFG

play_sound() {
    echo "1">/sys/class/gpio/gpio${SPEAKER_GPIO}/value
    $WYZEHACK_DIR/bin/audioplay $@ 1>/dev/null 2>&1
    echo "0">/sys/class/gpio/gpio${SPEAKER_GPIO}/value
}

set_passwd() {
    umount /etc
    rm -rf /tmp/etc
    cp -r /etc /tmp/
    echo $1 >/tmp/etc/shadow
    mount -o bind /tmp/etc /etc
}

wait_wlan() {
    while true
    do
        sleep 10
        if ! ifconfig wlan0 | grep "inet addr";
        then
            echo "wlan0 not ready yet..."
            continue
        fi
    done
}

hook_init() {
    if [ "$DEVICE_MODEL" == "V3" ];then
        return 0
    fi

    if [ ! -f $WYZEHACK_BIN ];
    then
        echo "wyze hack main binary not found: $WYZEHACK_BIN"
        return 1
    fi

    if [ ! -f $WYZEHACK_CFG ];
    then
        echo "wyze hack config file not found: $WYZEHACK_CFG"
        return 1
    fi

    local SYSTEM_DIR=${1:-/system}
    if [ ! -L $SYSTEM_DIR/init/app_init.sh ];
    then
        cp $SYSTEM_DIR/init/app_init.sh $SYSTEM_DIR/init/app_init_orig.sh
    fi

    local APP_INIT=$(readlink $SYSTEM_DIR/init/app_init.sh)
    if [ "$APP_INIT" != "$WYZEHACK_BIN" ];
    then
        ln -s -f $WYZEHACK_BIN $SYSTEM_DIR/init/app_init.sh
    fi

    return 0
}

log_sync() {
    local LOG_DIR=/media/mmcblk0p1/wyzehacks/log
    mkdir -p $LOG_DIR

    if [ -z "$SYNC_BOOT_LOG" ];
    then
        # This is to record device reboot time when log sync is not enabled
        CNT=$(ls $LOG_DIR/reboot_* | wc -l)
        let CNT=$CNT+1
        touch $LOG_DIR/reboot_$CNT

        # Log sync not enabled
        return 0
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
            echo "Waiting for system clock sync..."
            continue
        fi

        break
    done

    local CNT=0
    local TAIL_PID
    while true
    do
        if [ -z "$TAIL_PID" ];
        then
            tail -n +0 -f /tmp/boot.log > $LOG_DIR/boot_)date +"%Y%m%d%H%M%S")_$CNT.log 2>&1 &
            TAIL_PID=$!
            let CNT=$CNT+1
        fi

        sleep 60
        local LOGSIZE=$(wc /tmp/boot.log -c| awk '{print $1}')
        if [ "$LOGSIZE" -gt "1000000" ];
        then
            kill -9 $TAIL_PID
            unset TAIL_PID
            cp /tmp/boot.log /tmp/boot1.log
            echo "Log truncated" > /tmp/boot.log
        fi
    done
}

auto_archive() {
    if [ -z "$ARCHIVE_OLDER_THAN" ];
    then
        # Auto archive not enabled
        exit 0
    fi

    mkdir -p /media/mmcblk0p1/archive/record
    mkdir -p /media/mmcblk0p1/archive/alarm

    while true
    do
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
                local DST_FILE=$(echo "${DAY}_$SRC_FILE" | sed 's,/,_,g')
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

        sleep 1d
    done
}

auto_update() {
    if [ ! "$AUTO_UPDATE" == 1 ];then
        return 0
    fi

    local UPDATE_DIR=${UPDATE_DIR:-/mnt/WyzeCams/wyzehacks}
    echo "AUTO_UPDATE enabled, checking for update in $UPDATE_DIR..."

    UPDATE_DIR=$(ls -d $UPDATE_DIR/release_?_?_?? | sort -r | head -1)
    local UPDATE_FLAG=$UPDATE_DIR/${DEVICE_ID}.done

    if [ -z "$UPDATE_DIR" ]; then
        echo "Found no updates, skipping..."
        return 0
    fi

    echo "Found update $UPDATE_DIR, checking..."

    if [ -f "$UPDATE_FLAG" ]; then
        echo "Update $UPDATE_DIR already installed, skipping..."
        return 0
    fi

    echo "Installing update from $UPDATE_DIR..."
    touch $UPDATE_FLAG
    $UPDATE_DIR/telnet_install.sh
    echo "Update installed."
}

auto_reboot() {
    if [ -z "$REBOOT_AT" ];
    then
        # Auto reboot not enabled
        exit 0
    fi

    # Sleep 2 minute to avoid multiple reboots
    sleep 2m

    # Unfortunately we don't have cron job or at command in this environment, so use
    # a poorman's implementation
    local CUR_TIME
    while true
    do
        sleep 1m
        CUR_TIME=$(TZ=UTC date +"%H:%M")

        if [ "$CUR_TIME" == "$REBOOT_AT" ];
        then
            # Delay 60 seconds so the log can be captured by logsync process.
            echo "Autoreboot: rebooting camera..."
            reboot -d 60
        fi
    done
}

auto_config() {
    if [ ! "$AUTO_CONFIG" == 1 ];then
        return 0
    fi

    echo "AUTO_CONFIG enabled, checking for new config file..."
    local CONFIG_NEW=/media/mmc/wyzehacks/config.new
    if [ ! -f "$CONFIG_NEW" ];then
        echo "New config file not found, skipping..."
        return 0
    fi

    echo "Found new config file, checking..."
    set -e

    sed 's/\r$//' $CONFIG_NEW > /tmp/tmp_config

    local NEW_MD5=$(md5sum /tmp/tmp_config | grep -oE "^[0-9a-f]*")
    local CUR_MD5=$(md5sum $WYZEHACK_CFG | grep -oE "^[0-9a-f]*")

    if [ "$NEW_MD5" == "$CUR_MD5" ]; then
        echo "Nothing changed, skipping..."
        return 0
    fi

    echo "New config content:"
    echo "====================="
    cat /tmp/tmp_config
    echo "====================="

    echo "Checking if it's valid:"
    source /tmp/tmp_config

    if [ -z "$NFS_ROOT" ]; then
        echo "NFS_ROOT not set in the new config, abort..."
        return 1
    fi

    echo "Applying new config"
    cp /tmp/tmp_config $WYZEHACK_CFG

    echo "Content applied:"
    echo "====================="
    cat $WYZEHACK_CFG
    echo "====================="

    return 0
}

mount_nfs() {
    local NFS_MOUNT="/bin/mount $NFS_OPTIONS"
    while true
    do
        if $NFS_MOUNT $NFS_ROOT /mnt;
        then
            break
        fi
    
        echo "[$NFS_MOUNT $NFS_ROOT /mnt] failed, will retry in 5 seconds..."
        sleep 5
    done

    local CAM_DIR=/mnt/WyzeCams/$DEVICE_ID
    for DIR in /mnt/WyzeCams/*/;
    do
        if [ -f "$DIR/.mac_$DEVICE_ID" ];
        then
            CAM_DIR="$DIR"
            break
        fi
    done

    echo Mounting directory $CAM_DIR as SD card
    if [ ! -d "$CAM_DIR" ];
    then
        echo "Creating data directory [$CAM_DIR]"
        if ! mkdir -p "$CAM_DIR";
        then
            echo "[mkdir -p $CAM_DIR] failed"
            return 1
        fi
    fi

    echo "Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmcblk0p1"
    mkdir -p /media/mmcblk0p1
    if ! mount -o bind "$CAM_DIR" /media/mmcblk0p1;
    then
        echo "mount $CAM_DIR as /media/mmcblk0p1 failed"
        return 1
    fi

    echo "Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmc"
    mkdir -p /media/mmc
    if ! mount -o bind "$CAM_DIR" /media/mmc;
    then
        echo "mount $CAM_DIR as /media/mmc failed"
        return 1
    fi

    # So that we can memorize this folder even after renamed
    touch /media/mmcblk0p1/.mac_$DEVICE_ID
    ifconfig > /media/mmcblk0p1/ifconfig.txt 2>&1

    # Keep a copy of config.inc in <cam_dir>/wyzehacks directory, this allows
    # user to verify their current config and updating it by editing this file.
    mkdir -p /media/mmc/wyzehacks
    cp $WYZEHACK_CFG /media/mmc/wyzehacks/config.inc

    # Now we tell the system the SD card is inserted
    echo 0 > $WYZEHACK_DIR/mmc_gpio_value.txt
    $WYZEHACK_DIR/bin/hackutils mmc_insert
}

check_nfs() {
    # Detecting NFS share mount failure
    while true
    do
        /bin/mount > /tmp/mount.txt
        if ! grep "/media/mmcblk0p1 type nfs" /tmp/mount.txt > /dev/null 2>&1;
        then
            echo "NFS no longer mounted as /media/mmcblk0p1"
            break
        fi

        if ! grep "/media/mmc type nfs" /tmp/mount.txt > /dev/null 2>&1;
        then
            echo "NFS no longer mounted as /media/mmc"
            break
        fi

        if ( timeout -t 60 df -h 2>&1| grep -q 'Stale NFS');
        then
            echo "Stale NFS handle detected"
            break
        fi

        # Check for every 10 seconds
        sleep 10
    done

    if [ ! -z "$NOTIFICATION_VOLUME" ];
    then
        play_sound /usr/share/notify/CN/user_need_check.wav $NOTIFICATION_VOLUME
    fi

    # This will make the log sync flush logs
    killall sleep
    sync
    sleep 3
    /sbin/reboot
}

run() {
    # User configuration
    if [ ! -f $WYZEHACK_CFG ];
    then
        echo "Config file not found, clearing telnet password"
        PASSWD_SHADOW='root::10933:0:99999:7:::'
    fi

    # Log syncing
    if [ ! -z "$SYNC_BOOT_LOG" ];
    then
        exec 2>&1 >> /tmp/boot.log
    fi

    # Set hostname
    hostname ${HOSTNAME:-"WyzeCam-$(echo -n $DEVICE_ID | tail -c 4)"}

    echo "WyzeApp version:  $WYZEAPP_VER"
    echo "WyzeHack version: $WYZEHACK_VER"
    echo "app_init signature: $WYZEINIT_MD5"

    local INIT_SCRIPT="$WYZEHACK_DIR/init/$WYZEINIT_MD5/init.sh"
    if [ ! -f "$INIT_SCRIPT" ];
    then
        echo "Unknown app_init.sh signature:$WYZEINIT_MD5"
        INIT_SCRIPT="$WYZEHACK_DIR/init/unknown/init.sh"
    fi

    # Load init script for the current firmware version
    PATH=$WYZEHACK_DIR/bin:$PATH \
        LD_LIBRARY_PATH=$WYZEHACK_DIR/bin:$LD_LIBRARY_PATH \
        $INIT_SCRIPT &


    # Special handling for updates
    local RUN_WYZEHACK=1
    if [ -f /system/.upgrade ] || [ -f /configs/.upgrade ];
    then
        RUN_WYZEHACK=0
    fi

    if [ ! -f $WYZEHACK_CFG ];
    then
        RUN_WYZEHACK=0
    fi

    if [ "$RUN_WYZEHACK" == '0' ];
    then
        return
    fi

    wait_wlan
    if mount_nfs;
    then
        log_sync &
        auto_reboot &
        auto_archive &
        check_nfs
    fi
}

install() {
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

    echo "Starting wyze hack installer..."

    play_sound $WYZEHACK_DIR/snd/begin.wav 50

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
    telnetd

    # Swapping shadow file so we can telnetd in without password. This
    # is for debugging purpose.
    set_passwd 'root::10933:0:99999:7:::'
    if [ -z "$WYZEAPP_VER" ];
    then
        echo "Wyze version not found!!!"
        play_sound $WYZEHACK_DIR/snd/failed.wav 50
        return 1
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
        play_sound $WYZEHACK_DIR/snd/failed.wav 50
        return 1
    fi

    # Copying wyze_hack scripts
    echo "Copying wyze hack binary..."
    cp $THIS_BIN $WYZEHACK_BIN

    # Hook app_init.sh
    echo "Hooking up boot script..."
    if ! hook_init
    then
        echo "Hooking up boot script failed"
        play_sound $WYZEHACK_DIR/snd/failed.wav 50
        return 1
    fi

    play_sound $WYZEHACK_DIR/snd/finished.wav 50

    rm $SD_DIR/version.ini.old > /dev/null 2>&1	
    mv $SD_DIR/version.ini $SD_DIR/version.ini.old > /dev/null 2>&1
    reboot
}

ACTION=$1
shift

[ -z $ACTION ] || $ACTION $@
