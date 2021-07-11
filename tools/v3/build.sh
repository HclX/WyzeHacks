#!/bin/sh

build_root() {
    IN_DIR=$1
    OUT_DIR=$2

    TMP_DIR=$(mktemp -d -t ci-XXXXXXXXXX)
    echo "Using temporary directory $TMP_DIR..."

    ROOTFS_IN=$IN_DIR/rootfs.bin
    if [ ! -f "$ROOTFS_IN" ];then
        DEMO_IN=$IN_DIR/demo_wcv3.bin
        if [ ! -f "$DEMO_IN" ];then
            echo "Input file [$DEMO_IN] doesn't exist"
            return 1
        fi

        echo "Processing input image $DEMO_IN..."

        KERNEL_OFFSET=$((0x000040))
        ROOTFS_OFFSET=$((0x1F0040))
        APPFS_OFFSET=$((0x5C0040))

        #dd if=${DEMO_IN} of=$TMP_DIR/kernel.bin skip=$KERNEL_OFFSET count=$(($ROOTFS_OFFSET-$KERNEL_OFFSET)) bs=1
        dd if=${DEMO_IN} of=$TMP_DIR/rootfs.bin skip=$ROOTFS_OFFSET count=$(($APPFS_OFFSET-$ROOTFS_OFFSET)) bs=1 >/dev/null 2>&1
        #dd if=${DEMO_IN} of=$TMP_DIR/appfs.bin  skip=$APPFS_OFFSET  bs=1
    else
        cp $ROOTFS_IN $TMP_DIR/rootfs.bin
    fi

    unsquashfs -d $TMP_DIR/rootfs $TMP_DIR/rootfs.bin >/dev/null
    ROOTFS_VER=$(grep -i AppVer $TMP_DIR/rootfs/usr/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g')
    echo "Root FS version is '$ROOTFS_VER'."

    if [ -f $OUT_DIR/$ROOTFS_VER/rootfs.bin ]; then
        echo "File $OUT_DIR/$ROOTFS_VER/rootfs.bin already exists..."
    else
        mkdir -p $OUT_DIR/$ROOTFS_VER
        cp ./rcS $TMP_DIR/rootfs/etc/init.d/rcS
        touch $TMP_DIR/rootfs/etc/init.d/.wyzehacks
        mksquashfs $TMP_DIR/rootfs/ $TMP_DIR/rootfs2.bin -all-root -noappend -comp xz >/dev/null


        #ORIG_SIZE=$(wc -c < $TMP_DIR/rootfs.bin)
        #NEW_SIZE=$(wc -c < $TMP_DIR/rootfs2.bin)
        #dd if=/dev/zero bs=1 count=$(($ORIG_SIZE - $NEW_SIZE)) >> $TMP_DIR/rootfs2.bin
        mkdir -p $OUT_DIR
        cp $TMP_DIR/rootfs2.bin $OUT_DIR/$ROOTFS_VER/rootfs.bin
        echo "[$ROOTFS_VER]" >> $OUT_DIR/$ROOTFS_VER/versions.txt
        echo "Result image generated as '$OUT_DIR/$ROOTFS_VER/rootfs.bin'."
    fi
    rm -rf $TMP_DIR
}

set -e
cd $(dirname $0)

for dir in firmwares/*/; do
    build_root ${dir} ../../wyze_hack/rootfs
done
