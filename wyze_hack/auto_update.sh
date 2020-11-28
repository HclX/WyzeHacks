#!/bin/sh
if [ ! "$AUTO_UPDATE" == 1 ];then
    exit
fi

UPDATE_DIR=${UPDATE_DIR:-/mnt/WyzeCams/wyzehacks}
echo "AUTO_UPDATE enabled, checking for update in $UPDATE_DIR..."

UPDATE_DIR=`ls -d $UPDATE_DIR/release_?_?_?? | sort -r | head -1`
UPDATE_FLAG=$UPDATE_DIR/${DEVICE_ID}.done

if [ -z "$UPDATE_DIR" ]; then
    echo "Found no updates, skipping..."
    exit
fi

echo "Found update $UPDATE_DIR, checking..."

if [ -f "$UPDATE_FLAG" ]; then
    echo "Update $UPDATE_DIR already installed, skipping..."
    exit
fi

echo "Installing update from $UPDATE_DIR..."
touch $UPDATE_FLAG
$UPDATE_DIR/telnet_install.sh
echo "Update installed."
