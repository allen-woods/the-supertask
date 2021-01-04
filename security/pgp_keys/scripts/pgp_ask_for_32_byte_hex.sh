#!/bin/sh

pgp_ask_for_32_byte_hex() {
  echo "WARNING! Be sure to securely store the following value in a safe place."
  echo -n "Please paste randomly generated 32-byte hex string (hidden):"
  local read -s HEX_32
  pipe_write "name_of_pipe" ''"${HEX_32}"'' --overwrite
}