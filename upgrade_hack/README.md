WyzeCam support SD card based firmware upgrade and there is no signature
check or anything. So this feature can be used to run arbitrary command
if you have physical access to the device.

This example shows how to enable telnetd using this method. To do this,
following these steps:
1. Prepare an SD card with FAT format.
2. Copy copy the FIRMWARE_660R.bin and version.ini to the root directory
of the SD card.
3. Insert the card into the camera and wait for a couple seconds.
4. You should now have telnetd running on the camera.
5. The camera is at a pending reboot state, so you may want to reboot
the device manually to get it out of the state. Before doing that, make
sure you remove the SD card otherwise you will get into upgrade loop.
6. The script is also generating non-empty /configs/.Server_config file
to persist the telnetd across reboots.

To create your own firmware file, moidfy the content in "app" sub-directory,
and run build.sh to regenerate the firwmare and version.ini files.
