# Background
Wyze hack relies on replacing `/system/init/app_init.sh` to persist itself and
get loaded. This means at installation time it needs to be able to write to
`/system/init`. This works for v1, v2 and PAN camera because `/system/` is part
of `app` image, which is a `j2ffs` type image. This type is mounted writable.

However, with v3, the `app` image is now a `sqashfs`. This type of image is
always mounted readonly. This makes writing to `/system/` impossible at runtime.
So the only way to modify this directory is to modify the device image offline,
which basically means generating a new `demo.bin` file and flashing it. But even
this is not possible: V3 camera introduced signature verification on `demo.bin`.
Unless we know Wyze's private signing key, or we found a vulnerabilty in the
related code, a modified `demo.bin` won't be accepted.

Luckily, the signature verification is only for SD card recovery, not for
booting. So once you find a way to modify the flash content, the bootloader
will happily load whatever in the flash. That leads to this method.

**Although `V2`/`PAN` models don't need this method. Wyze's update often wipes
out changes made by wyzehack, causing it no longer functions after the update.
To sovle this issue once for all, I also made the same thing for `V2`/`PAN`. So
now you can optionally run `hack_init.sh` on all your cameras to prevent the
hack from being removed when applying an Wyze update.**

# Details
In this method, we will use Wyze's update mechanism to push special update onto
the camera to `fix` or `initialize` the camera so it can load wyze hack binary.
The update contains a modified `rootfs` image, and a script to burn the image
to the rootfs partition. Once applied, the modification we added will search for
 installed hack and load it at boot time.

The reason we modify `rootfs` instead of `app` partition, is that `app`
partition updates frequently, which means the modification will be lost when an
update is applied, but `rootfs` partition doesn't seem to be updated at all, so
this allows our modification persist through updates.

# Installation steps
1. First, use the SD card recovery method to install the correct base firmware.
They are under tools/firmwares. Use `4.36.x.x` for `V3`, `4.10.x.x` for `PAN`
and `4.9.x.x` for `V2`.
2. Just like how you run `remote_install.sh`, but this time run `hack_init.sh`
to apply the `init` modification on desired cameras. The script will list all
the cameras under your account, pick the one you want to try this out. I suggest
you try one device at a time. Try bring the camera nearby because you will need
to listen to the `click` sound to tell if the modification is successfully
applied.
3. After you confirm the device, verify that the script says something like
 `"GET /firmware.bin HTTP/1.1" 200 -`. This confirms that the update has been
pushed to the camera.
4. Now wait for a couple minutes, the camera should reboot once the flashing is
done. If the device is not rebooting after 5 minutes, something might be wrong
and you should manually power cycle the camera. If you have an SD card inserted,
there will be an `init.log` on the SD card with more detailed information.
5. If you are seeing the camera in boot loop, something had gone wrong, please
go back to step #1 and restart.
6. If the camera is booting up and functioning correctly, congratulations, your
camera is now capable of running wyze hacks across udpates. You can proceed with
the `remote_install.sh` method to install wyze hack release `0.5.01` or later.

# Some notes
* You don't need to do this `init` process again until you do a SD card firmware
recovery.

* If you have a v3 camera with serial cable wired, you can login with `root` and
password `WYom2020` from the serial console.

* The `init` process will also enable `telnetd` and change the password to
`ismart12` so you can telnet into it even without wyze hacks installed.
