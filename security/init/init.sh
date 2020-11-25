#!/bin/sh

function init_vault {
  local res=$(curl \
  --request PUT \
  --data @$(pwd)/json/sys_init.json \
  http://127.0.0.1:8200/v1/sys/init)

  echo "${res}"
}