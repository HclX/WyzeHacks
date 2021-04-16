# WyzeHacks
This project contains a set of scripts trying to provide additional features
not implemented by the official firmware. Currently, it provides the following
functions:
1. Enable telnetd on your camera.
2. Customize the default root password for telnet login.
3. Redirect all the recordings to an NFS share.
4. Redirect console logs into an NFS share.
5. Automatically reboot the camera at certain time.
6. Automatically archive the recordings.


## Remote install using remote_install.sh
This installation method emulates the Wyze App protocol to push the update to a
running camera. You will need the following for installation:
* A Linux-like environment with Python3.7 installed. If you are using linux, it
shouldn't be a problem. MacOS might also work but I didn't test that. WSL on
Windows, unfortunately, doesn't work due to its isolated network settings.
* The target camera should be in the same network to which your Linux
environment connects. If your camera is running in isolated vLAN, you may need
to adjust it temporarily.
* The target camera should be in a working condition which means you can see it
alive from the Wyze App.

To do the installation, please follow these steps:
1. Unzip your release archive a directory, and change your current working
directory to there.
2. Rename "config.inc.TEMPLATE" to "config.inc", and then update the content
properly.
3. Run "./remote_install.sh"
4. First time, it will ask your Wyze account and password, and it may also ask
for 2FA authentication.
5. The login credentials will be stored in a local file named ".tokens" for
future use so you don't need to enter username and password and 2FA everytime.
Make sure you don't share this file with anyone you don't trust.
6. The token seems to have an expiration period. So next time if you run into
error with something like "Access token error" please delete ".tokens" file and
restart.
7. Once correctly authenticated, it will go through all the Wyze Cameras under
your account, asking you for each of them if you want to push the wyzehack onto
that camera. Enter 'Y' if yes, otherwise 'N'. Press "Ctrl + C" twice to
interrupt the process.
8. Once confirmed, you will hear "installation begins" from the target camera,
and then "installation finished" confirming the installation.
9. When you are done, make sure delete ".tokens" file from that archive folder
to avoid accidental leak of your logins. 

## SD card install
SD card install only works when your camera is running firmware before version
4.9.6.156 (WyzeCamV2) or 4.10.6.156 (WyzeCam Pan).  You will need an SD card for
this purpose. Size of the SD card doesn't matter.

To do the installation, follow these steps:
1. Prepare an SD card with FAT32 format.
2. Extract the release archive to the root directory of SD card.
3. Make a copy of config.inc-TEMPLATE to the root of SD card, rename it to
config.inc, and update the content accordingly.
4. Insert the SD card into camera.
5. Wait until it says "installation finished, please remove the SD card"
6. Make sure you remove the SD card before the camera reboots as I've seen
strange behavior with SD card in it.
7. Now you should have telnet, and also the NFS recording functionality.

## Remote install using telnet_install.sh
This method works when you have telnet access, which is usually enabled after
you installed older version wyze hacks.

Here are the steps to follow:
1. Unzip the release archive to a NFS share where you can access from the
camera.
2. telnet into the device, and run telnet_install.sh from the NFS share.
3. Wait until it says "installation finished, please remove the SD card"
4. The device should reboot by itself in less than a minute and you should have
the latest hack installed.

### Automatically install a release on NFS share
In version 0.4.04 I added the "auto-update" mechanism allowing the camera to
automatically install a release from NFS share. This feature is by default
disabled so you have to manually enable it. Please check the config.inc.TEMPLATE
on how to use it.

# Uninstalling the wyzehacks
You can use one of the following ways to uninstall this hack:
## Use the built-in uninstall feature
Starting with version 0.5.01, you can tell the camera to uninstall wyzehacks by
placing a file at the following location:
  `<CamDir>/wyzehacks/uninstall`
Once the uninstallation finished, you will see a file `uninstall.done`
confirming the success of uninstallation, or a file `uninstall.failed` telling
something went wrong with the uninstallation.

## Do a manual telnet uninstall
With wyzehacks installed, you should have the telnet access available. You can
log into the camera and perform the following steps (for v1, v2 and PAN):
```
  cp /system/init/app_init_orig.sh /system/init/app_init.sh 
  rm /params/wyze_hack.*
```
Once you verified the above commands finished successfully you are no longer
having any wyzehacks related stuff on the camera.

NOTE: To telnet into the camera, you need the login with root user and its
password, default one for v1/v2 is `ismart12`. PAN's default password is unknown
so you will have to set your password shadow to allow you login. Check the
`PASSWD_SHADOW` section in `config.inc.TEMPLATE` on how to do that.

## Perform a SD card firmware recovery
This removes the wyzehacks boot straping code from the camera so that it will
not be loaded by the camera firmware. However, your configuration file remains
on the camera. Luckily there is not much sensentive information in that file.


# Features:
## NFS share naming:
  The per camera NFS share was named by the camera's MAC address, but it's very
  inconvinent to manage if you have many cameras. As a result, a recent change
  now supports customizing folder names. All you need is renaming the folder
  from desktop to whatever you want and reboot the camera. The camera should
  remember whatever folder is using and will continue recording into the renamed
  folder. This feature is automatically enabled with latest version so no need
  to change anything in the configuration file to use this feature.
## Auto rebooting:
  Now you can control rebooting your camera at a specific time of each day. I
  found it's useful when you notice sometimes the device is not behaving very
  well after running for a couple days. You will need to uncomment a variable in
  the configuration file to use this feature. 
## Password shadowing:
  The default root password for WyzeCam is wellknown. Since this hack will 
  enable telnetd it may pose a new threat. To avoid that, customize the password 
  to something only you know. You will need to uncomment a variable in the 
  configuration file to use this feature.
## Log syncing:
  For debugging purpose, I improved the log syncing mechanism so now you can 
  sync the boot console log into the NFS share at almost realtime. However, 
  this has some security concerns as the boot log contains your credentials. 
  To avoid that, this feature is only enabled if you uncomment a variable in 
  the configuration file. 

  !!!NEVER SHARE YOUR BOOT LOG FILE WITH OTHERS OR YOUR ACCOUNT CAN BE 
  COMPROMISED!!!
## Auto archiving:
  I noticed after accumulating many days of recordings, the camera is behaving 
  strangely when you try to playback the recordings from Wyze app. To avoid 
  that, now you can enable "auto archiving" feature by uncommenting a config 
  variable. Older recordings will be moved to a different location which is not 
  discoverable by the Wyze app. You can always review them from your desktop.
## SD card size emulation
  People reports the hack doesn't work with NFS shares bigger than a certain 
  size. So I added a SD card size emulation so that no matter how big your NFS 
  share is, the hack will always report an acceptable size with used space set 
  to zero unless your free space is less than 16GB, in which case, it will 
  report a 16GB SD card with the correct free space information.

# Disclaimer:
* This is just a personal fun project without extensive test, so use it at your 
own risk.
* Be nice to Wyze: Because of their effort we have a cheap platform to play
around. If you run into issues after installing this hack, make sure you verify
the issue is not caused by the hack itself before you call Wyze's customer
support or return the device.
* The NFS share will need to be writable. Things can happen to the files in that
share. For example, if you do a "format SD card" from the camera. In theory the
operations should be limitted to the specific directory mapped for a particular
camera, but I wouldn't rely on that. It's always good to setup a separate NFS
share just for this purpose and isolate it from all your other important 
documents.
* It is usually tested working on latest stable firmware and I don't have time
to do full testing for every older versions.
* Once installed, physical SD card will no longer be recognized by the camera.
* The log file contains sensitive account information, so do not share with 
others unless you don't mind your account being compromised.
* This hack enables telnetd on your camera. Since the username/password is 
wellknown, this may be a security concern if others can connect into your wifi 
network.
* I didn't test what will happen if your NFS server dies, so you are on your 
own...

# FAQ:
## My camera died, how can I recover it?
You will need to perform a SD card recovery with the following steps:
  1. Download the matching firmware from wyze.com
  2. Extract it to the root directory of an SD card, and make sure it's named 
  "demo.bin".
  3. Unplug the camera, and then insert the SD card
  4. Hold the reset button while you plugin the camera
  5. Wait for a couple seconds, release the reset button
  6. After some time, your camera should have the factory firmware installed.
  7. Please note this doesn't erase your configurations, which needs to be done 
  through a factory reset method.

## How do I uninstall the hack?
To uninstall the hack, I recommend you go through the SD card recovery method 
in #1 and then perform a factory reset.

## It keeps saying "installation failed", anyway to debug?
On SD card there should be a file named "install.log" containing every command
executed during the installation. It should give you a rough idea why it's
failing. The most likely failure reason would be missing configuration file.
Depending on how you install, you need to put the config.inc file to the right
location for the installer to pickup.

## My NFS share has more than 1TB space, why does it say only 128GB in the app?
The firwmare is designed to handle SD card, which usually has a much smaller
size. With large size like this, the firmware will behave incorrectly. To avoid
issues, the hack limits the emulated SD card to maximum 512GB. If your NFS share
has more than 16GB free space, you will see an SD card with the size set to your
available free space (capped to 128). If your share has a free space lower
than 16GB, the device will see a 16GB SD card, with free space set to your
actual free space.

## I don't get anything on my NFS share. What can go wrong?
If you hear the "installation finished successfully" message, but still don't
get any video recordings in the expected NFS share, it's very likely something
wrong with your NFS share configuration. A couple ways to debug this:
1. Check the SD card information from the app, if it says SD card not installed,
there is something wrong with your NFS config.
2. At this moment, you should have telnet enabled, try telnet into the camera
and run "mount" to see if you have the NFS share correctly mounted.
3. If mount shows no NFS file system is mounted, try to mount the share manually
with the following commands and see what error message you get:
```
source /params/wyze_hack.cfg
mount $NFS_OPTIONS $NFS_ROOT /mnt
```
5. At this point you will need to figure out what's wrong with your config file,
and try to see if you can fix it by tweaking NFS_ROOT and NFS_OPTIONS in file 
`/params/wyze_hack.cfg`. You can edit this file over telnet with `vi` command.

## I see files but no recordings on my NFS shares.
People report this kind of behavior and it seems to be caused by NFS share with
size larger than a certain amount. Try make a smaller share or use "NFS quota"
to limit the size. Issue #19 might be a related one.

## Known issues.
1. With release 0.4.00 and firmware 4.9.6.156 (WyzeCamV2) and 4.10.6.156 
(WyzeCam Pan), I noticed sometimes the NFS share will be unmounted. The root 
cause is still unclear, but I believe it may have something to do with 
firmware's bad SD card detection.
