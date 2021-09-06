#!/bin/sh

demo_patch() {
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

    IN_DIR=$(dirname $DEMO_IN)
    $IN_DIR/packer.sh unpack $DEMO_IN $TMP_DIR

    unsquashfs -d $TMP_DIR/rootfs $TMP_DIR/rootfs.bin >/dev/null

    chmod a+w $TMP_DIR/rootfs/etc/shadow
    cp -r patch/* $TMP_DIR/rootfs/
    cp -r $IN_DIR/patch/* $TMP_DIR/rootfs/
    chmod a-w $TMP_DIR/rootfs/etc/shadow

    touch $TMP_DIR/rootfs/etc/init.d/.wyzehacks
    mksquashfs $TMP_DIR/rootfs/ $TMP_DIR/rootfs2.bin -noappend -all-root -comp xz -info >/dev/null 2>&1

    ORIG_SIZE=$(wc -c < $TMP_DIR/rootfs.bin)
    NEW_SIZE=$(wc -c < $TMP_DIR/rootfs2.bin)
    FREE_SIZE=$(($ORIG_SIZE - $NEW_SIZE))

    echo "$FREE_SIZE bytes free space left."
    dd if=/dev/zero bs=1 count=$FREE_SIZE >> $TMP_DIR/rootfs2.bin

    $IN_DIR/packer.sh pack $TMP_DIR $DEMO_OUT
    cp $IN_DIR/version.txt $(dirname $DEMO_OUT)/

    if [ -z $DEBUG ]; then
        rm -rf $TMP_DIR
    fi
}

set -e
CUR_DIR=$(dirname $(readlink -f $0))

demo_patch $CUR_DIR/PAN/demo.bin $CUR_DIR/../installer/PAN/demo.bin
demo_patch $CUR_DIR/V2/demo.bin $CUR_DIR/../installer/V2/demo.bin
demo_patch $CUR_DIR/V3/demo_wcv3.bin $CUR_DIR/../installer/V3/demo_wcv3.bin
