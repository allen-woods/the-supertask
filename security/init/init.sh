#!/bin/sh

function init_vault {
  # Extended params:
  #   "pgp_keys": [
  #     "file1.asc",
  #     "file2.asc",
  #     "file3.asc"
  #   ],
  #   "root_token_pgp_key": "fileX.asc",
  local api_v1="http://127.0.0.1:8200/v1"
  local sys_init=/usr/local/init/sys_init.json
  local sys_init_addr=$api_v1/sys/init

  echo "** Begin Initialization **"

  curl \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -X PUT \
  -d @$sys_init \
  $sys_init_addr | jq

  local res=false

  echo "Verifying initialization..."
  while [ "$(echo -n $res | grep -w false)" = "false" ]; do
    res=$(curl \
    -s
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -X GET \
    $sys_init_addr)
  done

  echo "** Init OK! **"
  echo "$res" | jq
}