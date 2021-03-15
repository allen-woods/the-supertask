#!/bin/sh

migrate_files() {
  [ ! -d /persist ] && echo -e "\033[7;33mERROR: Directory \"/persist\" does not exist.\033[0m" && return 1
  [ ! -d /to_host ] && mkdir /to_host

  ls -la /persist

  mv -v /persist/* /to_host/
  rm -rf /persist
  echo -e "\033[7;33mFiles Migrated!\033[0m"
}