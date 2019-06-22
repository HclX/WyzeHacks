# WyzeHacks
Hacks I discovered allowing Wyze camera owners to do customizations. Currently
it supports the following functionalities:

1. Enable telnetd on your camera.
2. Redirect the recording to an NFS share.

To install, do the following steps:
1. Modify config.inc with your own NFS settings.
2. Prepare an SD card with FAT32 format.
3. Copy everything onto the root directory of SD card.
4. Insert the SD card into camera
5. Wait until the camera reboot
6. Now you should have telnet, and also the NFS recording functionality.
