#!/bin/sh

create_install_instructions() {
  mkfifo /tmp/instructs
  exec 3<> /tmp/instructs
  unlink /tmp/instructs
  printf '%s\n' \
  "instruct" \
  "names" \
  "go" \
  "here"
}