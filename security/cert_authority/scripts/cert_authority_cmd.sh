#!/bin/sh

# Add deps.
cmd_01() { apk.static add openssl; };
cmd_02() { apk.static add outils-jot; };
# Write randomly generated password into pipe.
cmd_03() { pipe_write "/name_of_pipe" $(random_string [[:alnum:]][[:punct:]] 20 99) --append; };
# Root config.
cmd_04() { mkdir -pm 0700 /tls/root/certs; };
cmd_05() { mkdir -m 0700 /tls/root/private; };
cmd_06() { echo 01 > /tls/root/serial; };
cmd_07() { touch /tls/root/index.txt; };
cmd_08() { cp /etc/ssl/openssl.cnf /tls/root/openssl.cnf.root; };
cmd_09() {
  local ROOT_CNF_PATH=/tls/root/openssl.cnf.root
  
  # Patches first.
  sed -i '45s/.\/demoCA/\/tls\/root/' $ROOT_CNF_PATH
  sed -i '51s/=\ \$dir\/newcerts/=\ \$dir\/certs/' $ROOT_CNF_PATH
  sed -i '53s/=\ \$dir\/cacert.pem/=\ \$dir\/certs\/cacert.pem/' $ROOT_CNF_PATH
  sed -i '77s/=\ default/=\ sha512/' $ROOT_CNF_PATH
  sed -i '108s/=\ 2048/=\ 4096/' $ROOT_CNF_PATH
  sed -i '131s/=\ AU/=\ US/' $ROOT_CNF_PATH
  sed -i '136s/=\ Some-State/=\ Washington/' $ROOT_CNF_PATH
  sed -i '141s/=\ Internet\ Widgits\ Pty\ Ltd/=\ The\ Supertask/' $ROOT_CNF_PATH
  sed -i '160s/=\ 4/=\ 20/' $ROOT_CNF_PATH # 128 bit, [[:alnum:]][[:punct:]]
  sed -i '161s/=\ 20/=\ 39/' $ROOT_CNF_PATH # 256 bit, [[:alnum:]][[:punct:]]

  # Inserts second.
  # sed -i '12a RANDFILE = \$ENV::HOME\/.rnd' $ROOT_CNF_PATH
  sed -i '109a default_md = sha512' $ROOT_CNF_PATH # Breaking?
  sed -i '139a localityName_default = SEATTLE' $ROOT_CNF_PATH
  sed -i '260a [ v3_intermediate_ca ]' $ROOT_CNF_PATH
  sed -i '261a subjectKeyIdentifier = hash' $ROOT_CNF_PATH
  sed -i '262a authorityKeyIdentifier = keyid:always,issuer' $ROOT_CNF_PATH
  sed -i '263a basicConstraints = critical, CA:true, pathlen:0' $ROOT_CNF_PATH
  sed -i '264a keyUsage = critical, digitalSignature, cRLSign, keyCertSign' $ROOT_CNF_PATH
}
# Intermediate config.
cmd_10() { mkdir -pm 0700 /tls/intermediate/certs; };
cmd_11() { mkdir -m 0700 /tls/intermediate/csr; };
cmd_12() { mkdir -m 0700 /tls/intermediate/private; };
cmd_13() { echo 01 > /tls/intermediate/serial; };
cmd_14() { touch /tls/intermediate/index.txt; };
cmd_15() { echo 01 > /tls/intermediate/crlnumber; };
cmd_16() { cp /tls/root/openssl.cnf.root /tls/intermediate/openssl.cnf.intermediate; };
cmd_17() {
  local INTERMEDIATE_CNF_PATH=/tls/intermediate/openssl.cnf.intermediate
  
  sed -i '46s/=\ \/tls\/root/=\ \/tls\/intermediate/' $INTERMEDIATE_CNF_PATH
  sed -i '54s/=\ \$dir\/certs\/cacert.pem/=\ \$dir\/certs\/intermediate.cacert.pem/' $INTERMEDIATE_CNF_PATH
  sed -i '59s/=\ \$dir\/private\/cakey.pem/=\ \$dir\/private\/intermediate.cakey.pem/' $INTERMEDIATE_CNF_PATH
  sed -i '84s/=\ policy_match/=\ policy_anything/' $INTERMEDIATE_CNF_PATH
}
# Root cert creation.
cmd_18() { cd /tls/root; };
cmd_19() {
  cmd_18
  echo "$(pipe_read "/name_of_pipe" 1 --no-delete)" | openssl genpkey \
  -out ./private/cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
}
cmd_20() {
  cmd_18
  echo "$(pipe_read "/name_of_pipe" 1 --no-delete)" | openssl req \
  -new \
  -x509 \
  -sha512 \
  -days 3650 \
  -passin stdin \
  -config ./openssl.cnf.root \
  -extensions v3_ca \
  -key ./private/cakey.pem \
  -out ./certs/cacert.pem \
  -outform PEM \
  -batch
}
# Intermediate cert creation.
cmd_21() { cd /tls/intermediate; };
cmd_22() {
  cmd_21
  echo "$(pipe_read "/name_of_pipe" 1 --no-delete)" | openssl genpkey \
  -out ./private/intermediate.cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
}
cmd_23() {
  cmd_21
  echo "$(pipe_read "/name_of_pipe" 1 --no-delete)" | openssl req \
  -new \
  -sha512 \
  -passin stdin \
  -config ./openssl.cnf.intermediate \
  -key ./private/intermediate.cakey.pem \
  -out ./csr/intermediate.csr.pem \
  -outform PEM \
  -batch
}
cmd_24() {
  cmd_21
  local ADMIN_CONTACT=$(cat $HOME/.admin | head -n1)
  echo "$(pipe_read "/name_of_pipe" 1 --delete-all)" | openssl ca \
  -config ./openssl.cnf.intermediate \
  -extensions v3_intermediate_ca \
  -days 365 \
  -notext \
  -batch \
  -passin stdin \
  -subj "/CN=Alpine 3-12 Intermediate CA/emailAddress=${ADMIN_CONTACT}/C=US/ST=Washington/L=Seattle/O=The Supertask" \
  -in ./csr/intermediate.csr.pem \
  -out ./certs/intermediate.cacert.pem
}
# # Certificate bundle.
# #
# # NOTE:
# # These functions will not be used per Vault's advice to only
# # provide the intermediate cert to Vault's config, not the root
# # cert.
# #
# # This means we can't pass a bundle to Vault safely.
# # Preserved here for convenience only.
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