#!/bin/sh
ACTION=$1

KERNEL_OFFSET=$((0x000040))
ROOTFS_OFFSET=$((0x200040))
DRIVER_OFFSET=$((0x550040))
APPFS_OFFSET=$((0x5F0040))

if [ "$ACTION" = "unpack" ]; then
    DEMO_IN=$2
    OUT_DIR=$3

    dd if=${DEMO_IN} of=$OUT_DIR/kernel.bin skip=$KERNEL_OFFSET count=$(($ROOTFS_OFFSET-$KERNEL_OFFSET)) bs=1
    dd if=${DEMO_IN} of=$OUT_DIR/rootfs.bin skip=$ROOTFS_OFFSET count=$(($DRIVER_OFFSET-$ROOTFS_OFFSET)) bs=1
    dd if=${DEMO_IN} of=$OUT_DIR/driver.bin skip=$DRIVER_OFFSET count=$(($APPFS_OFFSET-$DRIVER_OFFSET)) bs=1
    dd if=${DEMO_IN} of=$OUT_DIR/appfs.bin  skip=$APPFS_OFFSET  bs=1
elif [ "$ACTION" = "pack" ]; then
    TMP_DIR=$2
    DEMO_OUT=$3
    cat $TMP_DIR/kernel.bin $TMP_DIR/rootfs2.bin $TMP_DIR/driver.bin $TMP_DIR/appfs.bin > $TMP_DIR/flash.bin
    mkimage -A MIPS -O linux -T firmware -C none -a 0 -e 0 -n jz_fw -d $TMP_DIR/flash.bin $DEMO_OUT
else
    echo "Unknown action '$ACTION'"
fi
