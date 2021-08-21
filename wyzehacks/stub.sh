#!/bin/sh
export WYZEHACKS_BIN=$(readlink -f $0)
export WYZEHACKS_DIR=$(dirname $WYZEHACKS_BIN)
export WYZEHACKS_VER=__WYZEHACKS_VER__

PAYLOAD_START=`awk '/^#__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`
tail -n+$PAYLOAD_START $0 | gzip -cd | tar x -f - -C /tmp

exec sh /tmp/wyzehacks/main.sh "$@"
#__PAYLOAD_BELOW__
