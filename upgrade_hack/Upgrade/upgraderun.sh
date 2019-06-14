#!/bin/sh
echo "Hello from upgrade hack!!!"
telnetd
echo 1>/configs/.Server_config
while true; do echo 'Hit CTRL+C'; sleep 1; done


