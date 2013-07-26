#!/bin/bash
listen_address=$2
for nic in `ifconfig|grep -v ^\ |grep -v ^$|cut -f 1 -d \ `;do [ ! -z "`ifconfig $nic|grep -w ${listen_address}`" ] && eth=$nic;done
result=`arping -I ${eth} -w 5 -f -c 1 $1 | grep Received`
ok=`echo $result | cut -d \  -f 2`
if [ "$ok" == "1" ]; then
  echo "OK - $result"
  exit 0
else
  echo "CRITICAL - $result"
  exit 2
fi
