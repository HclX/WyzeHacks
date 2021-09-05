#!/bin/sh
ACTION=$1

KERNEL_OFFSET=$((0x000040))
ROOTFS_OFFSET=$((0x1F0040))
APPFS_OFFSET=$((0x5C0040))

if [ "$ACTION" = "unpack" ]; then
    DEMO_IN=$2
    OUT_DIR=$3

    dd status=none if=${DEMO_IN} of=$OUT_DIR/kernel.bin skip=$KERNEL_OFFSET count=$(($ROOTFS_OFFSET-$KERNEL_OFFSET)) bs=1
    dd status=none if=${DEMO_IN} of=$OUT_DIR/rootfs.bin skip=$ROOTFS_OFFSET count=$(($APPFS_OFFSET-$ROOTFS_OFFSET)) bs=1

    # Excluding the signature bytes
    IMAGE_END=$(($(stat -c %s ${DEMO_IN})-64))
    dd status=none if=${DEMO_IN} of=$OUT_DIR/appfs.bin  skip=$APPFS_OFFSET  count=$(($IMAGE_END-$APPFS_OFFSET)) bs=1
elif [ "$ACTION" = "pack" ]; then
    TMP_DIR=$2
    DEMO_OUT=$3
    cat $TMP_DIR/kernel.bin $TMP_DIR/rootfs2.bin $TMP_DIR/appfs.bin > $TMP_DIR/flash.bin
    mkimage -A MIPS -O linux -T firmware -C none -a 0 -e 0 -n jz_fw -d $TMP_DIR/flash.bin $DEMO_OUT

    # Appending dummy signature bytes
    dd status=none if=/dev/zero bs=1 count=64 >>$DEMO_OUT
else
    echo "Unknown action '$ACTION'"
fi
