#!/bin/sh

function add_packages {
  apk.static add openrc
  if [ $? -eq 0 ]
  then
    apk.static -U add haveged && \
    rc-update add haveged
  else
    return 1
  fi
  if [ $? -eq 0 ]
  then
    apk.static -U add \
    gnupg \
    openssl \
    outils-jot \
    rng-tools
  else
    return 1
  fi
}