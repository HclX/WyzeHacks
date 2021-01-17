#!/bin/sh
if [ ! "$AUTO_CONFIG" == 1 ];then
    exit
fi

echo "AUTO_CONFIG enabled, checking for new config file..."

CONFIG_NEW=/media/mmc/wyzehacks/config.inc
if [ ! -f "$CONFIG_NEW" ];then
    echo "New config file not found, skipping..."
    exit
fi

echo "Found new config file, checking..."
set -e

sed 's/\r$//' $CONFIG_NEW > /tmp/tmp_config

NEW_MD5=`md5sum /tmp/tmp_config | grep -oE "^[0-9a-f]*"`
CUR_MD5=`md5sum $WYZEHACK_CFG | grep -oE "^[0-9a-f]*"`

if [ "$NEW_MD5" == "$CUR_MD5" ]; then
    echo "Nothing changed, skipping..."
    exit
fi

echo "New config content:"
echo "====================="
cat /tmp/tmp_config
echo "====================="

echo "Checking if it's valid:"
source /tmp/tmp_config

if [ -z "$NFS_ROOT" ]; then
    echo "NFS_ROOT not set in the new config, abort..."
    exit
fi

echo "Applying new config"
cp /tmp/tmp_config $WYZEHACK_CFG

echo "Content applied:"
echo "====================="
cat $WYZEHACK_CFG
echo "====================="
