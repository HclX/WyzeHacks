#!/bin/sh
if [ -z "$SYNC_BOOT_LOG" ];
then
    # Log sync not enabled
    exit 0
fi

# Wait until the NTP client updated local time, so we can have correct log timestamp
touch /media/mmcblk0p1/.timestamp
while true
do
    sleep 5
    touch /tmp/.timestamp
    if [ /tmp/.timestamp -ot /media/mmcblk0p1/.timestamp ];
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
        mkdir -p /media/mmcblk0p1/log
        tail -n +0 -f /tmp/boot.log > /media/mmcblk0p1/log/boot_`date +"%Y%m%d%H%M%S"`_$CNT.log 2>&1 &
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
