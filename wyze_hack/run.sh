#!/bin/sh
SCRIPT_DIR=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_DIR`

if [ -f $SCRIPT_DIR/ver.inc ];
then
    source $SCRIPT_DIR/ver.inc
fi

echo "Running WyzeHacks version $SCRIPT_VER"

# User configuration
source $SCRIPT_DIR/config.inc

$SCRIPT_DIR/bind_etc.sh
$SCRIPT_DIR/mount_nfs.sh &

