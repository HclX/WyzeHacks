Wyze blocked the OTA update channel with their latest firmware and server side
changes. This makes installing WyzeHacks remotely impossible. However, there are
still ways to install it manually if you have physical access to your cameras.

Depending on whether you are doing a V3 or V2/PAN, the steps are slightly
different.

V3 camera has signature check in its bootloader preventing recovering the camera
to a modified image. However, this can be bypassed by modifying the bootloader.
To do that, you need telnet access to the camera, which, is blocked by latest
Wyze firmware. However, you can do this by rolling back your V3 camera to an
older version firmware, such as 4.3.2.280. You only need to do this step once
per camera:
1. Recover your wyze camera to firmware version 4.3.2.280 using the SD card
recovery method. Leave the SD card in the camera.
2. Now you need a Linux machine reachable from the camera via your local network.
3. Setup DNS spoof on your router to redirect domain name `d1fk93tz4plczb.cloudfront.net`
to the IP of your linux machine
3. Run WyzeUpdater with the following args:
```
./wyze_updater.py --token ~/.wyze_token update -d <your camera mac> -f firmwares/v3_unlockboot.bin -n d1fk93tz4plczb.cloudfront.net -p 18080
```
4. If everything goes well, you should see the camera fetches the update, and
then reboot after ~10 seconds.
5. After this step, you should be able to flash any modified demo_wcv3.bin file
to the camera using the SD card recovery method.
6. If something went wrong, you can find more information in `crack.log` on the
SD card.

Now we can proceed installing the latest wyze hacks:
1. If you are trying to do this on V3 camera, you need to first go through the
above step to unlock your camera's bootloader.
2. The latest WyzeHack requires an SD card in the camera to work. So prepare
your SD card, and extract everything to the root directory of the card.
3. Make a copy of wyze_hack/wyze_hack.cfg.TEMPLATE to wyze_hack/wyze_hack.cfg,
and modify it accordingly based on your environment.
4. Now depending the model of the camera you want to use with this SD card, move
the correct demo.bin or demo_wcv3.bin to the root directory.
5. Do a recovery with this SD card, and you should be all good to go.
6. Make sure you leave this SD card in the camera. All later version of the
WyzeHacks will require this card in the camera to work.
7. Now you can enjoy the hack again. But be careful with new update: some of the
update can reset the modifications, which means you will have to pull out your
ladder and do SD card installation again.
