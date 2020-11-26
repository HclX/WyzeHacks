# By default, load original app_init.sh with libhacks.so injected
LD_PRELOAD=$WYZEHACK_DIR/bin/libhacks.so /system/init/app_init_orig.sh
