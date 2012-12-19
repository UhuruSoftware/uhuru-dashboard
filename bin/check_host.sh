#!/bin/bash
result=`arping -w 5 -f -c 1 $1 | grep Received`
if [ $? -eq 0 ]; then
  echo "OK - $result"
  exit 0
else
  echo "CRITICAL - $result"
  exit 2
fi
