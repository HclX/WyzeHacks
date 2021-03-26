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

# Installation
The `initialization` of v3 camera's `rootfs` has been integrated into the wyze
hack installation script, so no special treatment is needed. However, it's worth
mention first time installation on v3 camera will be much longer due to the
rootfs flashing process.

# Some notes
* If you have a v3 camera with serial cable wired, you can login with `root` and
password `WYom2020` from the serial console.
