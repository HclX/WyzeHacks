#!/bin/sh
set -x
export THIS_MD5=`md5sum $0 | grep -oE "^[0-9a-f]*"`
export THIS_VER=__WYZEHACK_VER__
export THIS_BIN=$0

ACTION=${1:-run}
[ "$#" -gt 1 ] && shift

echo haha

export THIS_DIR=${TMP:-/tmp}/wyze_hack/$ACTION
mkdir -p $THIS_DIR

echo haha
PAYLOAD_START=`awk '/^#__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`
tail -n+$PAYLOAD_START $0 | gzip -cd | tar x -f - -C $THIS_DIR

echo haha

exec sh $THIS_DIR/main.sh $ACTION $@
#__PAYLOAD_BELOW__
