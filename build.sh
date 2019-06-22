#!/bin/sh
mkdir -p .tmp/Upgrade
echo FWGRADEUP=app > .tmp/Upgrade/PARA
cp install.sh .tmp/Upgrade/upgraderun.sh
cp -r wyze_hack .tmp/Upgrade/

tar -cvf ./FIRMWARE_660R.bin -C ./.tmp Upgrade
md5=$(md5sum ./FIRMWARE_660R.bin)
set -- junk $md5
shift
echo "[SD]" > ./version.ini
echo "version=9.9.9.9" >> ./version.ini
echo "type=1" >> ./version.ini
echo "md5=$1" >> ./version.ini

rm -rf .tmp
