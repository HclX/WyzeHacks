# WyzeHacks
Hacks I discovered allowing Wyze camera owners to do customizations. Currently
it supports the following functionalities:

1. Enable telnetd on your camera.
2. Redirect all the recordings to an NFS share.
3. Redirect console logs into NFS share as well for debugging purpose.

There are two ways to install this hack:
* When telnet is not enabled, you will need to use SD card installation method. To do it, following these steps:
  1. Prepare an SD card with FAT32 format.
  2. Copy FIRMWARE_660R.bin and version.ini onto the root directory of SD card.
  3. Make a copy of config.inc-TEMPLATE to the root of SD card, rename it to config.inc, and update the content accordingly.
  4. Insert the SD card into camera
  5. Wait until the camera reboot
  6. Now you should have telnet, and also the NFS recording functionality.
  7. Remove the SD card and then you should be good to go.
* When you already have telnet enabled, you can skip the SD card and do direct installation with the following steps:
  1. Put this repo into an NFS share which you can access from the device.
  2. Make a copy config.inc-TEMPLATE to the same directory, rename it to config.inc, and update the content accordingly
  3. telnet into the device, and run "install.sh" from the NFS share.
  4. You should be good to go.

NOTE:
1. This is just a personal fun project without extensive test, so use it at your own risk.
2. The NFS share will need to be writable. Because it's writable, if you do a "format SD card" from the camera, everyting under that share will be deleted. So I'd suggest use a separate NFS share and isolate it from all your other important documents.
3. This tested working on latest firmware (4.9.4.108).
4. You no longer need an SD card to be plugged into the camera.
5. The log file contains sensitive account information, so do not share with others unless you don't mind your account being compromised.
6. This hack enables telnetd on your camera. Since the username/password is wellknown, this may be a security concern if others can connect into your wifi network.
7. I didn't test what will happen if your NFS server dies, so you are on your own...


