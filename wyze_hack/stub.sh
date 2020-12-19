#!/bin/sh
if [ -d /params ];then
    export WYZEHACK_CFG=/params/wyze_hack.cfg
    export WYZEHACK_BIN=/params/wyze_hack.sh
    export DEVICE_ID=`grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g'`
    export DEVICE_MODEL="v2"
else
    export WYZEHACK_CFG=/configs/wyze_hack.cfg
    export WYZEHACK_BIN=/configs/wyze_hack.sh
    export DEVICE_ID=`grep -E -o CONFIG_INFO=[0-9A-F]+ /configs/.product_config | cut -c 13-24`
    export DEVICE_MODEL="v3"
fi

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
