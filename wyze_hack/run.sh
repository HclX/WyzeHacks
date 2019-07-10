#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`
$SCRIPT_DIR/mount_nfs.sh &
$SCRIPT_DIR/log_sync.sh &
