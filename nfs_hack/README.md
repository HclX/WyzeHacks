This hack allows a wyze camera to record onto an NFS share. An SD card is
still needed to trigger the recording, however, it can now be much smaller
and all your actual recordings will be on an NFS share you specified.

Do the following steps to use this hack:
1. Configure your NFS server so you can have a writable share. Due to
uncertainties all the content under this share may be deleted, so try isolate
this share from your other shares.
2. Download this directory in this directory into /system/bin/nfs_hack.
3. Modify config.inc with your NFS server information.
4. Modify /system/init/app_init.sh to run nfs_hack in background, before
the line of iCamera. It should be something like the following:
```
      <...other content...>
      /system/bin/singleBoadTest
      /system/bin/nfs_hack/run.sh
      /system/bin/iCamera
      <...other content...>
```

I've tested this on my camera, but I have no gurantee everything works well.
Let me know if you run into issues.
