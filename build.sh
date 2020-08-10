#!/bin/sh
. wyze_hack/hack_ver.inc

cp -u src/dummymmc/dummy_mmc.ko wyze_hack/bin/
cp -u src/utils/libhacks.so wyze_hack/bin/
cp -u src/utils/uevent_recv wyze_hack/bin/
cp -u src/utils/uevent_send wyze_hack/bin/


RELEASE=`echo "$WYZEHACK_VER"|tr '.' '_'`
mkdir -p ./release/$RELEASE
rm -rf ./release/$RELEASE/*
rm ./release/wyze_hacks_$RELEASE.zip

mkdir -p .tmp/Upgrade
echo FWGRADEUP=app > .tmp/Upgrade/PARA
sed "s/__WYZEHACK_VER__/$WYZEHACK_VER/g" wyze_hack.sh > .tmp/Upgrade/wyze_hack.sh
tar --sort=name --owner=root:0 --group=root:0 --mtime='1970-01-01' -cz -O wyze_hack >>.tmp/Upgrade/wyze_hack.sh
cp ./upgraderun.sh .tmp/Upgrade/
tar --sort=name --owner=root:0 --group=root:0 --mtime='1970-01-01' -cf ./release/$RELEASE/FIRMWARE_660R.bin -C ./.tmp Upgrade
rm -rf .tmp

cp ./WyzeUpdater/wyze_updater.py ./release/$RELEASE/
cp ./telnet_install.sh ./release/$RELEASE/
cp ./remote_install.sh ./release/$RELEASE/
cp ./config.inc.TEMPLATE ./release/$RELEASE/
MD5=`md5sum ./release/$RELEASE/FIRMWARE_660R.bin | grep -oE "^[0-9a-f]*"`

cat > ./release/$RELEASE/version.ini << EOL
[SD]
version=9.9.9.9
type=1
md5=$MD5
EOL

zip -j ./release/wyze_hacks_$RELEASE.zip ./release/$RELEASE/*
cp ./release/config.inc ./release/$RELEASE/
