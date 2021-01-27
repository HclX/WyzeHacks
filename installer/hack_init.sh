#!/bin/sh
cd $(dirname $0)

DEBUG=""
if [ "$1" = "--debug" ]; then
    DEBUG="$1"
fi

python3 -m pip install requests
python3 ./wyze_updater.py --token ~/.wyze_token $DEBUG update \
    -m WYZEC1-JZ -m WYZECP1_JEF -m WYZE_CAKP2JFUS -m WYZEDB3 -f ./hack_init.bin -p 11808
