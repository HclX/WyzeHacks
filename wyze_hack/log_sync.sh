#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

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
