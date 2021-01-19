#!/bin/sh
set -e

DEMO_IN=$1
ROOTFS_OUT=$2

if [ -z "$ROOTFS_OUT" ];then
    echo "Usage: mkimage.sh <demo.bin> <out_file>"
    exit 1
fi

if [ ! -f "$DEMO_IN" ];then
    echo "Input file [$DEMO_IN] doesn't exist"
    exit 2
fi

cd $(dirname $0)

TMP_DIR=$(mktemp -d -t ci-XXXXXXXXXX)
echo "Using temporary directory $TMP_DIR..."

KERNEL_OFFSET=$((0x000040))
ROOTFS_OFFSET=$((0x1F0040))
APPFS_OFFSET=$((0x5C0040))

#dd if=${DEMO_IN} of=$TMP_DIR/kernel.bin skip=$KERNEL_OFFSET count=$(($ROOTFS_OFFSET-$KERNEL_OFFSET)) bs=1
dd if=${DEMO_IN} of=$TMP_DIR/rootfs.bin skip=$ROOTFS_OFFSET count=$(($APPFS_OFFSET-$ROOTFS_OFFSET)) bs=1
#dd if=${DEMO_IN} of=$TMP_DIR/appfs.bin  skip=$APPFS_OFFSET  bs=1

unsquashfs -d $TMP_DIR/rootfs $TMP_DIR/rootfs.bin
cp ./rcS $TMP_DIR/rootfs/etc/init.d/rcS
touch $TMP_DIR/rootfs/etc/init.d/.wyzehacks
mksquashfs $TMP_DIR/rootfs/ $TMP_DIR/rootfs2.bin -noappend -comp xz

ORIG_SIZE=$(wc -c < $TMP_DIR/rootfs.bin)
NEW_SIZE=$(wc -c < $TMP_DIR/rootfs2.bin)

dd if=/dev/zero bs=1 count=$(($ORIG_SIZE - $NEW_SIZE)) >> $TMP_DIR/rootfs2.bin

cp $TMP_DIR/rootfs2.bin $ROOTFS_OUT
#cat $TMP_DIR/kernel.bin $TMP_DIR/rootfs2.bin $TMP_DIR/appfs.bin > $TMP_DIR/flash.bin
#mkimage -A MIPS -O linux -T firmware -C none -a 0 -e 0 -n jz_fw -d $TMP_DIR/flash.bin $DEMO_OUT

# rm -rf $TMP_DIR
