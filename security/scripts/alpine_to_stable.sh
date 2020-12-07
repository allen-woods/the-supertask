#!/bin/sh

function alpine_to_stable {
  echo "----> Upgrading Alpine to Stable Release."

  sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' \
  /etc/apk/repositories && \
  apk update && \
  apk add busybox-static apk-tools-static && \
  apk.static upgrade --no-self-upgrade --available --simulate

  # If no errors happened, apply the upgrade.
  if [ $? -eq 0 ]
  then
    apk.static upgrade --no-self-upgrade --available
  else
    # Throw an error.
    exit 1
  fi
}


