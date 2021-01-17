#!/bin/sh
LOG_DIR=/media/mmcblk0p1/wyzehacks/log
mkdir -p $LOG_DIR

if [ -z "$SYNC_BOOT_LOG" ];
then
    # This is to record device reboot time when log sync is not enabled
    CNT=`ls $LOG_DIR/reboot_* | wc -l`
    let CNT=$CNT+1
    touch $LOG_DIR/reboot_$CNT

    # Log sync not enabled
    exit 0
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

CNT=0
while true
do
    if [ -z "$TAIL_PID" ];
    then
        tail -n +0 -f /tmp/boot.log > $LOG_DIR/boot_`date +"%Y%m%d%H%M%S"`_$CNT.log 2>&1 &
        TAIL_PID=$!
        let CNT=$CNT+1
    fi

    sleep 60
    LOGSIZE=`wc /tmp/boot.log -c| awk '{print $1}'`
    if [ "$LOGSIZE" -gt "1000000" ];
    then
        kill -9 $TAIL_PID
        unset TAIL_PID
        cp /tmp/boot.log /tmp/boot1.log
        echo "Log truncated" > /tmp/boot.log
    fi
done
