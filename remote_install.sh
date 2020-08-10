#!/bin/sh

cp ./FIRMWARE_660R.bin ./firmware.bin

if [ -f config.inc ]; then
    echo "Found local config file, including into firmware update archive..."
    tar -rvf ./firmware.bin ./config.inc --xform=s,./,Upgrade/,g
fi

python3 ./wyze_updater.py update \
    -m WYZEC1-JZ -m WYZECP1_JEF -f ./firmware.bin -p 8080
