#!/bin/sh

apk add busybox-static apk-tools-static
sed -ie 's/v3\.10/v3.12/g' /etc/apk/repositories
apk.static update
apk.static upgrade --no-self-upgrade --available --simulate
if [ $? -eq 0 ]
then
  apk.static upgrade --no-self-upgrade --available
fi