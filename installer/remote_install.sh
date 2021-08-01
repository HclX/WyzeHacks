#!/bin/sh
cd $(dirname $0)

cp ./FIRMWARE_660R.bin ./firmware.bin

if [ -f config.inc ]; then
    echo "Found local config file, including into firmware update archive..."
    mkdir -p ./Upgrade
    cp config.inc ./Upgrade
    tar -rvf ./firmware.bin Upgrade/config.inc
fi

DEBUG=""
if [ "$1" = "--debug" ]; then
    DEBUG="$1"
fi

python3 -m pip install requests
python3 ./wyze_updater.py --token ~/.wyze_token $DEBUG update \
    -m WYZEC1-JZ -m WYZECP1_JEF -m WYZE_CAKP2JFUS -m WYZEDB3 \
    -f ./firmware.bin \
    -n d1fk93tz4plczb.cloudfront.net -p 11808
