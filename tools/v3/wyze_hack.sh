#!/bin/sh

umount /etc
rm -rf /tmp/etc
cp -r /etc /tmp/

PASSWD_SHADOW="root::10933:0:99999:7:::"
echo $PASSWD_SHADOW >/tmp/etc/shadow

mount -o bind /tmp/etc /etc

while true
do
  if ! pidof telnetd;
  then
    telnetd
  fi

  sleep 10
done

/system/init/app_init.sh &
