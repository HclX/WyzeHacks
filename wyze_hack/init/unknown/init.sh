# By default, load original app_init.sh with libhacks.so injected
LD_PRELOAD=$WYZEHACK_DIR/bin/libhacks.so $WYZEINIT_SCRIPT &
