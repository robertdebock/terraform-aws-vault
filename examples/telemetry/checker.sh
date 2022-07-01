#!/bin/sh

while [ 1 ] ; do
  result=$(curl -v https://telemetry.robertdebock.nl:8200/ui/ 2>&1)
  
  if (echo "${result}" | grep '< HTTP/2' | grep 200 > /dev/null 2>&1) ; then
    echo "$(date) OKAY"
  else
    echo "$(date) FAIL"
    echo "${result}"
  fi
done
