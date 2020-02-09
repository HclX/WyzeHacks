#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

if $SCRIPT_DIR/wyze_hack.sh install;
then
    /sbin/reboot
fi
