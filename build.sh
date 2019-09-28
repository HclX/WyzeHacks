#!/bin/sh
mkdir -p .tmp/Upgrade
echo FWGRADEUP=app > .tmp/Upgrade/PARA
cp install.sh .tmp/Upgrade/upgraderun.sh
cp -r wyze_hack .tmp/Upgrade/

tar -cvf ./release/FIRMWARE_660R.bin -C ./.tmp Upgrade

MD5=`md5sum ./release/FIRMWARE_660R.bin | grep -oE "^[0-9a-f]*"`

cat > ./release/version.ini << EOL
[SD]
version=9.9.9.9
type=1
md5=$MD5
EOL

mkdir -p ./release/debug

rm -rf .tmp
