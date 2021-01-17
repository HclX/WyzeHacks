#!/bin/sh
export THIS_BIN=$(readlink -f $0)
export THIS_DIR=$(dirname $THIS_BIN)
export THIS_MD5=`md5sum $THIS_BIN | grep -oE "^[0-9a-f]*"`
export THIS_VER=__WYZEHACK_VER__

ACTION=${1:-run}
[ "$#" -gt 1 ] && shift

WYZEHACK_DIR=${TMP:-/tmp}/wyze_hack/$ACTION
mkdir -p $WYZEHACK_DIR

PAYLOAD_START=`awk '/^#__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`
tail -n+$PAYLOAD_START $0 | gzip -cd | tar x -f - -C $WYZEHACK_DIR

exec sh $WYZEHACK_DIR/main.sh $ACTION $@
#__PAYLOAD_BELOW__
