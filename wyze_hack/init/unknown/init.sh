# By default, load original app_init.sh with libhacks.so injected
if [ "$DEVICE_MODEL" == "v2" ];then
    LD_PRELOAD=$WYZEHACK_DIR/bin/libhacks.so /system/init/app_init_orig.sh
else
    LD_PRELOAD=$WYZEHACK_DIR/bin/libhacks.so /system/init/app_init.sh
fi