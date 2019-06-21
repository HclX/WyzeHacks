#!/bin/sh
echo "Hello from upgrade hack!!!"

telnetd
echo 1>/configs/.Server_config

echo "telnetd enabled, press enter to reboot ..."
read
mv /media/mmcblk0p1/version.ini /media/mmcblk0p1/version.ini.old
