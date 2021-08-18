#!/bin/sh

build_root() {
    DEMO_IN=$1
    DEMO_OUT=$2

    if [ ! -f "$DEMO_IN" ];then
        echo "Input file [$DEMO_IN] doesn't exist"
        return 1
    fi

    if [ -f "$DEMO_OUT" ] && [ -z "$CLEAN" ];then
        echo "Output file [$DEMO_OUT] already exists, skipping..."
        return 0
    fi

    echo "Processing input image $DEMO_IN..."

    TMP_DIR=$(mktemp -d -t wh-XXXXXXXXXX)
    echo "Using temporary directory $TMP_DIR..."

    ./packer.sh unpack $DEMO_IN $TMP_DIR

    unsquashfs -d $TMP_DIR/rootfs $TMP_DIR/rootfs.bin >/dev/null
    ROOTFS_VER=$(grep -i AppVer $TMP_DIR/rootfs/usr/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g')
    echo "Root FS version is '$ROOTFS_VER'."

    chmod a+w $TMP_DIR/rootfs/etc/shadow
    cp -r ./patch/* $TMP_DIR/rootfs/
    chmod a-w $TMP_DIR/rootfs/etc/shadow

    touch $TMP_DIR/rootfs/etc/init.d/.wyzehacks
    mksquashfs $TMP_DIR/rootfs/ $TMP_DIR/rootfs2.bin -noappend -all-root -comp xz >/dev/null

    ORIG_SIZE=$(wc -c < $TMP_DIR/rootfs.bin)
    NEW_SIZE=$(wc -c < $TMP_DIR/rootfs2.bin)
    dd if=/dev/zero bs=1 count=$(($ORIG_SIZE - $NEW_SIZE)) >> $TMP_DIR/rootfs2.bin

    ./packer.sh pack $TMP_DIR $DEMO_OUT

    if [ -z $DEBUG ]; then
        rm -rf $TMP_DIR
    fi
}

set -e
CUR_DIR=$(dirname $(readlink -f $0))

cd $CUR_DIR/v2
for dir in firmwares/*/; do
    build_root ${dir}demo.bin ${dir}demo_hack.bin
done

cd $CUR_DIR/v3
for dir in firmwares/*/; do
    build_root ${dir}demo_wcv3.bin ${dir}demo_wcv3_hack.bin
done
