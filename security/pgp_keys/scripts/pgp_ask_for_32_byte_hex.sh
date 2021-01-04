#!/bin/sh

pgp_ask_for_32_byte_hex() {
  # This function will be rewritten to make use of an injected file.
  
  # echo "WARNING! Be sure to securely store the following value in a safe place."
  # echo -n "Please paste randomly generated 32-byte hex string (hidden):"
  # local read -s HEX_32
  # pipe_write "name_of_pipe" ''"${HEX_32}"'' --overwrite
}