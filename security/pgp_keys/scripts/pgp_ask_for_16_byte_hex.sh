#!/bin/sh

pgp_ask_for_16_byte_hex() {
  echo "WARNING! Be sure to securely store the following value in a safe place."
  echo -n "Please paste randomly generated 16-byte hex string (hidden):"
  local read -s HEX_16
  pipe_write "name_of_pipe" ''"${HEX_16}"'' --append
}