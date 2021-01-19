#!/bin/sh
umount /etc
rm -rf /tmp/etc
cp -r /etc /tmp/

PASSWD_SHADOW='root:$1$MYSALT$3Sy1OLRk4kTa7P6fvzwp71:10933:0:99999:7:::'
echo $PASSWD_SHADOW >/tmp/etc/shadow

mount -o bind /tmp/etc /etc

/system/init/app_init.sh &

while true
do
  if ! pidof telnetd;
  then
    telnetd
  fi

  sleep 10
done
