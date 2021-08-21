#!/bin/sh
set -e
cd $(dirname $0)

. wyzehacks/hack_ver.inc

echo "Building release $WYZEHACKS_VER ..."

RELEASE=`echo "$WYZEHACKS_VER"|tr '.' '_'`
rm ./release/wyzehacks_$RELEASE.zip 2>/dev/null || true

sed "s/__WYZEHACKS_VER__/$WYZEHACKS_VER/g" ./wyzehacks/stub.sh > installer/wyzehacks/wyzehacks.bin
tar \
    --sort=name \
    --owner=root:0 \
    --group=root:0 \
    --mtime='1970-01-01' \
    -cz -O wyzehacks \
    >> installer/wyzehacks/wyzehacks.bin

chmod a+x installer/wyzehacks/wyzehacks.bin
( cd installer && zip -r ../release/wyzehacks_$RELEASE.zip * -x wyzehacks/wyzehacks.cfg );

rm -rf ./release/release_$RELEASE
unzip -q ./release/wyzehacks_$RELEASE.zip -d ./release/release_$RELEASE
if [ -f ./installer/wyzehacks/wyzehacks.cfg ];then
    cp ./installer/wyzehacks/wyzehacks.cfg ./release/release_$RELEASE/wyzehacks
fi
echo "Release $WYZEHACKS_VER build finished."
