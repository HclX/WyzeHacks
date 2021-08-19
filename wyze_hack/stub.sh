#!/bin/sh
export WYZEHACK_BIN=$(readlink -f $0)
export WYZEHACK_DIR=$(dirname $WYZEHACK_BIN)
export WYZEHACK_VER=__WYZEHACK_VER__

PAYLOAD_START=`awk '/^#__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`
tail -n+$PAYLOAD_START $0 | gzip -cd | tar x -f - -C /tmp

exec sh /tmp/wyze_hack/main.sh "$@"
#__PAYLOAD_BELOW__
