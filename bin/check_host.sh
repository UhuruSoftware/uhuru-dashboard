#!/bin/bash
eth=`ifconfig | grep eth | awk '{print $1}'`
result=`arping -I ${eth} -w 5 -f -c 1 $1 | grep Received`
ok=`echo $result | cut -d \  -f 2`
if [ "$ok" == "1" ]; then
  echo "OK - $result"
  exit 0
else
  echo "CRITICAL - $result"
  exit 2
fi
