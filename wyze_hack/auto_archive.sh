#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

if [ -z "$ARCHIVE_OLDER_THAN" ];
then
    # Auto archive not enabled
    exit 0
fi

mkdir -p /media/mmcblk0p1/archive/record
mkdir -p /media/mmcblk0p1/archive/alarm

while true
do
    for DAY in `ls -d /media/mmcblk0p1/record/???????? 2>/dev/null| sort | head -n -$ARCHIVE_OLDER_THAN 2>/dev/null| grep -oE "[0-9]{8}$"`;
    do
        SRC_DIR=/media/mmcblk0p1/record/$DAY
        DST_DIR=/media/mmcblk0p1/archive/record/$DAY

        if [ ! -d $SRC_DIR ];
        then
            continue
        fi

        for SRC_FILE in `find "$SRC_DIR" -name *.mp4 2>/dev/null| grep -oE "[0-9]{2}/[0-9]{2}\.mp4$"`;
        do
            DST_FILE=`echo "${DAY}_$SRC_FILE" | sed 's,/,_,g'`
            if [ ! -d $DST_DIR ];
            then
                mkdir -p $DST_DIR
            fi

            mv -n $SRC_DIR/$SRC_FILE $DST_DIR/$DST_FILE
        done
        rmdir $SRC_DIR/* $SRC_DIR
    done

    for DAY in `ls -d /media/mmcblk0p1/alarm/???????? 2>/dev/null| sort | head -n -$ARCHIVE_OLDER_THAN 2>/dev/null| grep -oE "[0-9]{8}$"`;
    do
        SRC_DIR=/media/mmcblk0p1/alarm/$DAY
        DST_DIR=/media/mmcblk0p1/archive/alarm/$DAY

        mv -n $SRC_DIR $DST_DIR
    done

    sleep 1d
done
