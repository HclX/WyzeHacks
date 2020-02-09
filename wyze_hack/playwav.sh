#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

if [ -f /sys/class/gpio/gpio63/value ];
then
    echo "1">/sys/class/gpio/gpio63/value
fi

$SCRIPT_DIR/bin/audioplay $@ 1>/dev/null 2>&1

if [ -f /sys/class/gpio/gpio63/value ];
then
    echo "0">/sys/class/gpio/gpio63/value
fi

