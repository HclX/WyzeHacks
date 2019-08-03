#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

# User configuration
source $SCRIPT_DIR/config.inc

$SCRIPT_DIR/bind_etc.sh
$SCRIPT_DIR/mount_nfs.sh &
$SCRIPT_DIR/log_sync.sh &
