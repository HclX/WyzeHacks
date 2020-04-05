# WyzeHacks
This project contains a set of scripts to provide additional features not possible or implemented by the official wyze camera firmware. Currently, it provides the following functions:
1. Enable telnetd on your camera.
2. Customize the default root password for telnet login.
3. Redirect all the recordings to an NFS share.
4. Redirect console logs into an NFS share.
5. Automatically reboot the camera at certain time.
6. Automatically archive the recordings.

INSTALLATION:
The latest release archive can be found in the release folder or from the github release page. There are two ways to install this hack:
* First time install, or after factory reset/firmware update. This means there is no wyzehack currently running on the camera. In this case you will need to use the SD card installation method:
  1. Prepare an SD card with FAT32 format.
  2. Extract the release archive to the root directory of SD card.
  3. Make a copy of config.inc-TEMPLATE to the root of SD card, rename it to config.inc, and update the content accordingly.
  4. Insert the SD card into camera
  5. Wait until it says "installation finished, please remove the SD card"
  6. Make sure you remove the SD card before the camera reboots as I've seen strange behavior with SD card in it.
  7. Now you should have telnet, and also the NFS recording functionality.

* When you are updating a camera with older wyzehack running. In this case physical SD card will no longer be recognized, so you need to install it from the telnet:
  1. Put this repo into an NFS share where you can access from the device.
  2. telnet into the device, and run install.sh from the NFS share.
  3. Wait until it says "installation finished, please remove the SD card"
  4. The device should reboot by itself in less than a minute and you should have the latest hack installed.


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
3. This tested working on latest firmware (4.9.5.111/4.10.5.111).
4. Once installed, physical SD card will no longer be recognized by the camera.
5. The log file contains sensitive account information, so do not share with others unless you don't mind your account being compromised.
6. This hack enables telnetd on your camera. Since the username/password is wellknown, this may be a security concern if others can connect into your wifi network.
7. I didn't test what will happen if your NFS server dies, so you are on your own...

FAQ:
1. My camera died, how can I recover it?
You will need to perform a SD card recovery with the following steps:
  1. Download the matching firmware from wyze.com
  2. Extract it to the root directory of an SD card, and make sure it's named "demo.bin".
  3. Unplug the camera, and then insert the SD card
  4. Hold the reset button while you plugin the camera
  5. Wait for a couple seconds, release the reset button
  6. After some time, your camera should have the factory firmware installed.
* Please note this doesn't erase your configurations, which needs to be done through a factory reset method.

2. How do I uninstall the hack?
To uninstall the hack, I recommend you go through the SD card recovery method in #1.

3. The installation doesn't work for me, anyway to debug?
On SD card there should be a file named "install.log" containing the actual error message if anything failed during the install.
