#!/bin/sh
export WYZEHACK_CFG=/params/wyze_hack.cfg
export WYZEHACK_BIN=/params/wyze_hack.sh

export THIS_MD5=`md5sum $0 | grep -oE "^[0-9a-f]*"`
export THIS_VER=__WYZEHACK_VER__
export THIS_BIN=$0

ACTION=$1
shift
if [ -z "$ACTION" ];
then
    ACTION=run
fi

TARGET_DIR=/tmp/$ACTION
mkdir -p $TARGET_DIR
export THIS_DIR=$TARGET_DIR/wyze_hack

PAYLOAD_START=`awk '/^#__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`
tail -n+$PAYLOAD_START $0 | gzip -cd | tar x -f - -C $TARGET_DIR
exec sh $THIS_DIR/$ACTION.sh $@
#__PAYLOAD_BELOW__
