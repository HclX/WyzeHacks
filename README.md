# WyzeHacks
Hacks I discovered allowing Wyze camera owners to do customizations. Currently
it supports the following functionalities:

1. Enable telnetd on your camera.
2. Redirect the recording to an NFS share.

To install, do the following steps:
1. Prepare an SD card with FAT32 format.
2. Copy FIRMWARE_660R.bin and version.ini onto the root directory of SD card.
3. Make a copy config.inc-TEMPLATE to the root of SD card, rename it to config.inc, and update the content accordingly.
4. Insert the SD card into camera
5. Wait until the camera reboot
6. Now you should have telnet, and also the NFS recording functionality.

NOTE:
1. This is just a personal fun project without extensive test, so use it at your own risk.
2. The NFS share will need to be writable. Because it's writable, if you do a "format SD card" from the camera, everyting under that share will be deleted. So I'd suggest use a separate NFS share and isolate it from all your other important documents.

