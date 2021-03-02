#!/bin/sh

# TODO: Create individual functions for each line below.
create_keys() {
  openssl rand -out payload_aes 32
  openssl rand -out ephemeral_aes 32
  openssl genpkey -out private.pem -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096
  openssl rsa -in private.pem -inform PEM -out public.pem -outform PEM -pubout
  openssl enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < ephemeral_aes) -iv A65959A6 -in payload_aes -out payload_wrapped
  openssl pkeyutl -encrypt -in ephemeral_aes -out ephemeral_wrapped -pubin -inkey public.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha1 -pkeyopt rsa_mgf1_md:sha1
  cat ephemeral_wrapped payload_wrapped > rsa_aes_wrapped
}