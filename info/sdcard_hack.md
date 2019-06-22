The SD card file management has a command injection vulnerability: When the
SD card is almost full, it will try to delete the older recordings. This is
done by enumerating all the directories under "/record". However, it only
looks for directories with 8 characters in the directory name. They are sorted
by the alphabet order to find the oldest one. Once found, "rm -rf \<path\>"
will be executed. The directory name is not sanitized before runing the
command, leading to command injection.

However, because of the 8-character directory name limitation, this exploit is
not easy to user. So far, I found only one way to start "telnetd" using this:

1. Prepare a small size SD card, larger ones are OK but you will need more
time to fill it.
2. Format the SD card
3. Fill the SD card with garbage data to almost full, not sure exactly how
much, but for 1GB card, ~60% capacity is good enough.
4. Create a directory with path "/record/;telnetd" on the card.
5. Insert the card into the camera, wait for a couple minutes
6. Your camera should be running "telnetd" now, you can login with user name
"root" and password "ismart12"

Once you get a root shell, you can persist the telnetd by either modifying the
starting script, or simply "echo 1>/configs/.Server_config" to tell the camera
app to start telnetd for you.


