#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

if [ -z "$REBOOT_AT" ];
then
    # Auto reboot not enabled
    exit 0
fi

# Sleep 2 minute to avoid multiple reboots
sleep 2m

# Unfortunately we don't have cron job or at command in this environment, so use
# a poorman's implementation
while true
do
    sleep 1m
    CUR_TIME=`TZ=UTC date +"%H:%M"`

    if [ "$CUR_TIME" == "$REBOOT_AT" ];
    then
        # Delay 60 seconds so the log can be captured by logsync process.
        echo "Autoreboot: rebooting camera..."
        reboot -d 60
    fi
done
