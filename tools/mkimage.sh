#!/bin/sh
set -x
set -e

DEMO_IN=$1
ROOTFS_OFFSET=$2
ROOTFS_SIZE=$3
RCS_FILE=$4
ROOTFS_OUT=$5

if [ -z "$ROOTFS_OUT" ];then
    echo "Usage: mkimage.sh <demo.bin> <rootfs_offset> <rootfs_size> <out_file>"
    exit 1
fi

if [ ! -f "$DEMO_IN" ];then
    echo "Input file [$DEMO_IN] doesn't exist"
    exit 2
fi

TMP_DIR=$(mktemp -d -t ci-XXXXXXXXXX)
echo "Using temporary directory $TMP_DIR..."

dd if=${DEMO_IN} of=$TMP_DIR/rootfs.bin skip=$ROOTFS_OFFSET count=$(($ROOTFS_SIZE)) bs=1
unsquashfs -d $TMP_DIR/rootfs $TMP_DIR/rootfs.bin
cp $RCS_FILE $TMP_DIR/rootfs/etc/init.d/rcS
touch $TMP_DIR/rootfs/etc/init.d/.wyzehacks
mksquashfs $TMP_DIR/rootfs/ $TMP_DIR/rootfs2.bin -noappend -comp xz

cp $TMP_DIR/rootfs2.bin $ROOTFS_OUT
#rm -rf $TMP_DIR
