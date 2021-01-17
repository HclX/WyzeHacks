#!/bin/sh
set -e
cd $(dirname $0)

. wyze_hack/hack_ver.inc

echo "Building release $WYZEHACK_VER ..."

RELEASE=`echo "$WYZEHACK_VER"|tr '.' '_'`
rm ./release/wyze_hacks_$RELEASE.zip 2>/dev/null || true

mkdir -p .tmp/Upgrade
echo FWGRADEUP=app > .tmp/Upgrade/PARA
sed "s/__WYZEHACK_VER__/$WYZEHACK_VER/g" ./wyze_hack/stub.sh > .tmp/Upgrade/wyze_hack.sh
tar \
    --sort=name \
    --owner=root:0 \
    --group=root:0 \
    --mtime='1970-01-01' \
    --dereference \
    -cz -O -C wyze_hack . >>.tmp/Upgrade/wyze_hack.sh

chmod a+x .tmp/Upgrade/wyze_hack.sh
cp ./wyze_hack/upgraderun.sh .tmp/Upgrade/
tar \
    --sort=name \
    --owner=root:0 \
    --group=root:0 \
    --mtime='1970-01-01' \
    --dereference -cf ./installer/FIRMWARE_660R.bin -C ./.tmp Upgrade
# rm -rf .tmp

MD5=`md5sum ./installer/FIRMWARE_660R.bin | grep -oE "^[0-9a-f]*"`

cat > ./installer/version.ini << EOL
[SD]
version=9.9.9.9
type=1
md5=$MD5
EOL

zip -r -j ./release/wyze_hacks_$RELEASE.zip ./installer -x *.inc *.tokens @

rm -rf ./release/release_$RELEASE
unzip -q ./release/wyze_hacks_$RELEASE.zip -d ./release/release_$RELEASE
if [ -f ./installer/config.inc ];then
    cp ./installer/config.inc ./release/release_$RELEASE
fi
echo "Release $WYZEHACK_VER build finished."