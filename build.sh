#!/bin/sh
. wyze_hack/hack_ver.inc

mkdir -p .tmp/Upgrade
echo FWGRADEUP=app > .tmp/Upgrade/PARA

sed "s/__WYZEHACK_VER__/$WYZEHACK_VER/g" wyze_hack.sh > .tmp/Upgrade/wyze_hack.sh
tar -cvz -O wyze_hack >>.tmp/Upgrade/wyze_hack.sh

cp upgraderun.sh .tmp/Upgrade/

tar -cvf ./release/FIRMWARE_660R.bin -C ./.tmp Upgrade

MD5=`md5sum ./release/FIRMWARE_660R.bin | grep -oE "^[0-9a-f]*"`

cat > ./release/version.ini << EOL
[SD]
version=9.9.9.9
type=1
md5=$MD5
EOL

rm -rf .tmp
