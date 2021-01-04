#!/bin/sh

# Add deps.
cmd_01() { apk.static add openssl; };
cmd_02() { apk.static add outils-jot; };
# Write randomly generated password into pipe.
cmd_03() { pipe_write "name_of_pipe" ''"$(random_string [[:alnum:]][[:punct:]] 20 99)"'' --append; };
# Root config.
cmd_04() { mkdir -pm 0700 /tls/root/certs; };
cmd_05() { mkdir -m 0700 /tls/root/private; };
cmd_06() { echo 01 > /tls/root/serial; };
cmd_07() { touch /tls/root/index.txt; };
cmd_08() { cp /etc/ssl/openssl.cnf /tls/root/openssl.cnf.root; };
cmd_09() { cert_authority_patch_root_cnf; };
# Intermediate config.
cmd_10() { mkdir -pm 0700 /tls/intermediate/certs; };
cmd_11() { mkdir -m 0700 /tls/intermediate/csr; };
cmd_12() { mkdir -m 0700 /tls/intermediate/private; };
cmd_13() { echo 01 > /tls/intermediate/serial; };
cmd_14() { touch /tls/intermediate/index.txt; };
cmd_15() { echo 01 > /tls/intermediate/crlnumber; };
cmd_16() { cp /tls/root/openssl.cnf.root /tls/intermediate/openssl.cnf.intermediate; };
cmd_17() { cert_authority_patch_intermediate_cnf; };
# Root cert creation.
cmd_18() { cd /tls/root; };
cmd_19() {
  cmd_17 && $(pipe_read "name_of_pipe" 1 --no-delete) | openssl genpkey \
  -out private/cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes_256_gcm \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
}
cmd_20() {
  cmd_17 && $(pipe_read "name_of_pipe" 1 --no-delete) | openssl req \
  -new \
  -x509 \
  -sha512 \
  -days 3650 \
  -passin stdin \
  -config openssl.cnf.root \
  -extensions v3_ca \
  -key private/cakey.pem \
  -out certs/cacert.pem \
  -outform PEM
}
# Intermediate cert creation.
cmd_21() { cd /tls/intermediate; };
cmd_22() {
  cmd_20 && $(pipe_read "name_of_pipe" 1 --no-delete) | openssl genpkey \
  -out private/intermediate.cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes_256_gcm \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
}
cmd_23() {
  cmd_20 && $(pipe_read "name_of_pipe" 1 --no-delete) | openssl req \
  -new \
  -sha512 \
  -days 365 \
  -passin stdin \
  -config openssl.cnf.intermediate \
  -key private/intermediate.cakey.pem \
  -out csr/intermediate.csr.pem \
  -outform PEM
}
cmd_24() {
  cmd_20 && $(pipe_read "name_of_pipe" 1 --delete-all) | openssl ca \
  -config openssl.cnf.intermediate
  -extensions v3_intermediate_ca
  -days 365
  -notext
  -batch
  -passin stdin
  -in csr/intermediate.csr.pem
  -out certs/intermediate.cacert.pem
  -outform PEM
}
# # Certificate bundle.
# #
# # NOTE:
# # These functions will not be used per Vault's advice to only
# # provide the intermediate cert to Vault's config, not the root
# # cert.
# #
# # This means we can't pass a bundle to Vault safely.
# #
# cmd_25() {
#   cat \
#   /tls/intermediate/certs/intermediate.cacert.pem \
#   /tls/root/certs/cacert.pem > tls/intermediate/certs/ca-chain-bundle.cert.pem
# }
# cmd_26() {
#   openssl verify \
#   -CAfile \
#   /tls/root/certs/cacert.pem \
#   /tls/intermediate/certs/ca-chain-bundle.cert.pem
# }
cmd_len() { echo 24; };