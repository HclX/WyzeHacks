#!/bin/sh
set -e
cd $(dirname $0)

. wyze_hack/hack_ver.inc

echo "Building release $WYZEHACK_VER ..."

RELEASE=`echo "$WYZEHACK_VER"|tr '.' '_'`
rm ./release/wyze_hacks_$RELEASE.zip 2>/dev/null || true

mkdir -p .tmp
sed "s/__WYZEHACK_VER__/$WYZEHACK_VER/g" ./wyze_hack/stub.sh > .tmp/wyze_hack.sh
tar \
    --sort=name \
    --owner=root:0 \
    --group=root:0 \
    --mtime='1970-01-01' \
    -cz -O wyze_hack \
    >>.tmp/wyze_hack.sh

chmod a+x .tmp/wyze_hack.sh
zip -r -j ./release/wyze_hacks_$RELEASE.zip .tmp/wyze_hack.sh installer/wyze_hack.cfg.TEMPLATE

rm -rf ./release/release_$RELEASE
unzip -q ./release/wyze_hacks_$RELEASE.zip -d ./release/release_$RELEASE
if [ -f ./installer/wyze_hack.cfg ];then
    cp ./installer/wyze_hack.cfg ./release/release_$RELEASE
fi
echo "Release $WYZEHACK_VER build finished."
