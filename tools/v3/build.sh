#!/bin/sh

build_root() {
    DEMO_IN=$1
    ROOTFS_OUT=$2

    if [ ! -f "$DEMO_IN" ];then
        echo "Input file [$DEMO_IN] doesn't exist"
        return 1
    fi

    echo "Processing input image $DEMO_IN..."

    TMP_DIR=$(mktemp -d -t ci-XXXXXXXXXX)
    echo "Using temporary directory $TMP_DIR..."

    KERNEL_OFFSET=$((0x000040))
    ROOTFS_OFFSET=$((0x1F0040))
    APPFS_OFFSET=$((0x5C0040))

    #dd if=${DEMO_IN} of=$TMP_DIR/kernel.bin skip=$KERNEL_OFFSET count=$(($ROOTFS_OFFSET-$KERNEL_OFFSET)) bs=1
    dd if=${DEMO_IN} of=$TMP_DIR/rootfs.bin skip=$ROOTFS_OFFSET count=$(($APPFS_OFFSET-$ROOTFS_OFFSET)) bs=1 >/dev/null 2>&1
    #dd if=${DEMO_IN} of=$TMP_DIR/appfs.bin  skip=$APPFS_OFFSET  bs=1

    unsquashfs -d $TMP_DIR/rootfs $TMP_DIR/rootfs.bin >/dev/null
    ROOTFS_VER=$(grep -i AppVer $TMP_DIR/rootfs/usr/app.ver | sed -E 's/^.*=[[:space:]]*([0-9.]+)[[:space:]]*$/\1/g')
    echo "Root FS version is '$ROOTFS_VER'."

    if [ -f $ROOTFS_OUT/$ROOTFS_VER.bin ]; then
        echo "File $ROOTFS_OUT/$ROOTFS_VER.bin already exists..."
    else
        cp ./rcS $TMP_DIR/rootfs/etc/init.d/rcS
        touch $TMP_DIR/rootfs/etc/init.d/.wyzehacks
        mksquashfs $TMP_DIR/rootfs/ $TMP_DIR/rootfs2.bin -noappend -comp xz >/dev/null


        #ORIG_SIZE=$(wc -c < $TMP_DIR/rootfs.bin)
        #NEW_SIZE=$(wc -c < $TMP_DIR/rootfs2.bin)
        #dd if=/dev/zero bs=1 count=$(($ORIG_SIZE - $NEW_SIZE)) >> $TMP_DIR/rootfs2.bin
        mkdir -p $ROOTFS_OUT
        cp $TMP_DIR/rootfs2.bin $ROOTFS_OUT/$ROOTFS_VER.bin
        echo "Result image generated as '$ROOTFS_OUT/$ROOTFS_VER.bin'."
    fi
    rm -rf $TMP_DIR
}

set -e
cd $(dirname $0)

for dir in firmwares/*/; do
    build_root ${dir}demo_wcv3.bin ../../wyze_hack/rootfs
done
