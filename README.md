# WyzeHacks
This project contains a set of scripts to provide additional features not possible or implemented by the official wyze camera firmware. Currently, it provides the following functions:
1. Enable telnetd on your camera.
2. Customize the default root password for telnet login.
3. Redirect all the recordings to an NFS share.
4. Redirect console logs into an NFS share.
5. Automatically reboot the camera at certain time.
6. Automatically archive the recordings.


INSTALLATION:
There are two ways to install this hack:
* First time install, or after factory reset/firmware update. This means there is no wyzehack currently running on the camera. In this case you will need to use the SD card installation method:
  1. Prepare an SD card with FAT32 format.
  2. Copy FIRMWARE_660R.bin and version.ini onto the root directory of SD card.
  3. Make a copy of config.inc-TEMPLATE to the root of SD card, rename it to config.inc, and update the content accordingly.
  4. Insert the SD card into camera
  5. Wait until the camera reboot
  6. Now you should have telnet, and also the NFS recording functionality.
  7. Remove the SD card and then you should be good to go.

* When you are updating a camera with older wyzehack running. In this case physical SD card will no longer be recognized, so you need to install it from the telnet:
  1. Put this repo into an NFS share where you can access from the device.
  2. Make a copy config.inc-TEMPLATE to the same directory, rename it to config.inc, and update the content accordingly
  3. telnet into the device, and run "install.sh" from the NFS share.
  4. Once the script finishes, reboot the camera by typing "reboot" from the telnet console.


A couple new features:
1. NFS share naming:
  The per camera NFS share was named by the camera's MAC address, but it's very inconvinent to manage if you have many cameras. As a result, a recent change now support customizing the folder name. All you need is renaming the folder from desktop to whatever you want and reboot the camera. The camera should remember whatever folder is using and will continue recording into the renamed folder. This feature is automatically enabled with latest version so no need to change anything in the configuration file to use this feature.
2. Auto rebooting:
  Now you can control rebooting your camera at a specific time of each day. I found it's useful when you notice sometimes the device is not behaving very well after running for a couple days. You will need to uncomment a variable in the configuration file to use this feature. 
3. Password shadowing:
  The default root password for WyzeCam is wellknown. Since this hack will enable telnetd it may pose a new threat. To avoid that, customize the password to something only you know. You will need to uncomment a variable in the configuration file to use this feature.
4. Log syncing:
  For debugging purpose, I improved the log syncing mechanism so now you can sync the boot console log into the NFS share at almost realtime. However, this has some security concerns as the boot log contains your credentials. To avoid that, this feature is only enabled if you uncomment a variable in the configuration file. !!!NEVER SHARE YOUR BOOT LOG FILE WITH OTHERS OR YOUR ACCOUNT CAN BE COMPROMISED!!!
5. Auto archiving:
  I noticed after accumulating many days of recordings, the camera is behaving strangely when you try to playback the recordings from Wyze app. To avoid that, now you can enable "auto archiving" feature by uncomment a configuration variable. Older recordings will be moved to a different location which is not discoverable by the wyze app. You can always review them from your desktop.

NOTE:
1. This is just a personal fun project without extensive test, so use it at your own risk.
2. The NFS share will need to be writable. Because it's writable, if you do a "format SD card" from the camera, everyting under that share will be deleted. So I'd suggest use a separate NFS share and isolate it from all your other important documents.
3. This tested working on latest firmware (4.9.4.108).
4. You no longer need an SD card to be plugged into the camera.
5. The log file contains sensitive account information, so do not share with others unless you don't mind your account being compromised.
6. This hack enables telnetd on your camera. Since the username/password is wellknown, this may be a security concern if others can connect into your wifi network.
7. I didn't test what will happen if your NFS server dies, so you are on your own...


