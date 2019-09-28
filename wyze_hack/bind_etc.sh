#!/bin/sh
if [ -z "$PASSWD_SHADOW" ];
then
    echo "PASSWD_SHADOW not configured, keeping original password..."
    exit 1
fi

umount /etc
rm -rf /tmp/etc
cp -r /etc /tmp/
echo $PASSWD_SHADOW >/tmp/etc/shadow
mount -o bind /tmp/etc /etc
telnetd
