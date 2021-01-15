#!/bin/sh

create_instructions() {
  mkfifo /tmp/instructs
  exec 3<> /tmp/instructs
  unlink /tmp/instructs
  printf '%s\n' \
  "instruct" \
  "names" \
  "go" \
  "here"
}

read_instruction() {
  read -u3 INSTALL_FUNC_NAME
}

delete_instructions() {
  exec 3>&-
  rm -f /tmp/instructs
}