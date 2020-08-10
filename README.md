# WyzeHacks
This project contains a set of scripts to provide additional features not possible or implemented by the official wyze camera firmware. Currently, it provides the following functions:
1. Enable telnetd on your camera.
2. Customize the default root password for telnet login.
3. Redirect all the recordings to an NFS share.
4. Redirect console logs into an NFS share.
5. Automatically reboot the camera at certain time.
6. Automatically archive the recordings.

# Release notes
## 0.4.0:
* Support firmware version 4.9.6.156 (WyzeCamV2) and 4.10.6.156 (WyzeCam Pan).
* Due to new firmware blocking SD card installation, a new WyzeApp protocol based remote installation method is added.
* SD card size emulation to make sure the hack works with large NFS shares.

# Download and installation
The latest release archive can be found in the [release folder](https://github.com/HclX/WyzeHacks/tree/master/release). You will need to unzip the release archive before proceed. Depending on the firmware version your camera is running, you may have two or three different approaches to install the hack.

## Remote install using remote_install.sh
This installation method emulates the Wyze App protocol to push the update to a running camera. You will need the following for installation:
* A Linux environment with Python3 installed. If you are using linux, that shouldn't be a problem. If you are running Windows 10, the WSL (Windows Subsystem of Linux) should be enough.
* The target camera should be in the same network to which your Linux environment connects. If your camera is running in isolated vLAN, you may need to adjust it temporarily.
* The target camera should be in a working condition which means you can see it alive from the Wyze App.

To do the installation, please follow these steps:
1. Unzip your release archive a directory, and change your current working directory to there.
2. Rename "config.inc.TEMPLATE" to "config.inc", and then update the content properly.
3. Run "./remote_install.sh"
4. First time, it will ask your Wyze account and password, and it may also ask for 2FA authentication.
5. The login credentials will be stored in a local file named ".tokens" for future use so you don't need to enter username and password and 2FA everytime. Make sure you don't share this file with anyone you don't trust.
5. Once correctly authenticated, it will go through all the Wyze Cameras under your account, asking you for each of them if you want to push the wyzehack onto that camera. Enter 'Y' if yes, otherwise 'N'. Press "Ctrl + C" twice to interrupt the process.
6. Once confirmed, you will hear "installation begins" from the target camera, and then "installation finished" confirming the installation.
7. When you are done, make sure delete ".tokens" file from that archive folder to avoid accidental leak of your logins. 

## SD card install
SD card install only works when your camera is running firmware before version 4.9.6.156 (WyzeCamV2) or 4.10.6.156 (WyzeCam Pan).  You will need an SD card for this purpose. Size of the SD card doesn't matter.

To do the installation, follow these steps:
1. Prepare an SD card with FAT32 format.
2. Extract the release archive to the root directory of SD card.
3. Make a copy of config.inc-TEMPLATE to the root of SD card, rename it to config.inc, and update the content accordingly.
4. Insert the SD card into camera.
5. Wait until it says "installation finished, please remove the SD card"
6. Make sure you remove the SD card before the camera reboots as I've seen strange behavior with SD card in it.
7. Now you should have telnet, and also the NFS recording functionality.

## Remote install using telnet_install.sh
This method works when you have telnet access, which is usually enabled after you installed older version wyze hacks.

Here are the steps to follow:
1. Unzip the release archive to a NFS share where you can access from the camera.
2. telnet into the device, and run telnet_install.sh from the NFS share.
3. Wait until it says "installation finished, please remove the SD card"
4. The device should reboot by itself in less than a minute and you should have the latest hack installed.

# Features:
## NFS share naming:
  The per camera NFS share was named by the camera's MAC address, but it's very inconvinent to manage if you have many cameras. As a result, a recent change now support customizing the folder name. All you need is renaming the folder from desktop to whatever you want and reboot the camera. The camera should remember whatever folder is using and will continue recording into the renamed folder. This feature is automatically enabled with latest version so no need to change anything in the configuration file to use this feature.
## Auto rebooting:
  Now you can control rebooting your camera at a specific time of each day. I found it's useful when you notice sometimes the device is not behaving very well after running for a couple days. You will need to uncomment a variable in the configuration file to use this feature. 
## Password shadowing:
  The default root password for WyzeCam is wellknown. Since this hack will enable telnetd it may pose a new threat. To avoid that, customize the password to something only you know. You will need to uncomment a variable in the configuration file to use this feature.
## Log syncing:
  For debugging purpose, I improved the log syncing mechanism so now you can sync the boot console log into the NFS share at almost realtime. However, this has some security concerns as the boot log contains your credentials. To avoid that, this feature is only enabled if you uncomment a variable in the configuration file. !!!NEVER SHARE YOUR BOOT LOG FILE WITH OTHERS OR YOUR ACCOUNT CAN BE COMPROMISED!!!
## Auto archiving:
  I noticed after accumulating many days of recordings, the camera is behaving strangely when you try to playback the recordings from Wyze app. To avoid that, now you can enable "auto archiving" feature by uncomment a configuration variable. Older recordings will be moved to a different location which is not discoverable by the wyze app. You can always review them from your desktop.
## SD card size emulation
  People reports the hack doesn't work with NFS shares bigger than a certain size. So I added a SD card size emulation so that no matter how big your NFS share is, the hack will always report an acceptable size with used space set to zero unless your free space is less than 64GB, in which case, it will report a 64GB SD card with the correct free space information.

# Notes:
* This is just a personal fun project without extensive test, so use it at your own risk.
* The NFS share will need to be writable. Because it's writable, if you do a "format SD card" from the camera, everyting under that share will be deleted. So I'd suggest use a separate NFS share and isolate it from all your other important documents.
* This tested working on latest firmware (4.9.6.156/4.10.6.156).
* Once installed, physical SD card will no longer be recognized by the camera.
* The log file contains sensitive account information, so do not share with others unless you don't mind your account being compromised.
* This hack enables telnetd on your camera. Since the username/password is wellknown, this may be a security concern if others can connect into your wifi network.
* I didn't test what will happen if your NFS server dies, so you are on your own...

# FAQ:
## My camera died, how can I recover it?
You will need to perform a SD card recovery with the following steps:
  1. Download the matching firmware from wyze.com
  2. Extract it to the root directory of an SD card, and make sure it's named "demo.bin".
  3. Unplug the camera, and then insert the SD card
  4. Hold the reset button while you plugin the camera
  5. Wait for a couple seconds, release the reset button
  6. After some time, your camera should have the factory firmware installed.
  7. Please note this doesn't erase your configurations, which needs to be done through a factory reset method.

## How do I uninstall the hack?
To uninstall the hack, I recommend you go through the SD card recovery method in #1.

## The installation doesn't work for me, anyway to debug?
On SD card there should be a file named "install.log" containing the actual error message if anything failed during the install.
