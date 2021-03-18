#!/bin/sh

# Name: install_tls.sh
# Desc: A collection of methods that must be called in proper sequence to install a specific set of data.
#       Certain methods are standardized and must appear, as follows:
#         - check_skip_install    A method for checking if the install should be skipped.
#         - create_instructions   A method for creating a non-blocking pipe to store instruction names.
#         - read_instruction      A method for reading instruction names from the non-blocking pipe.
#         - update_instructions   A method for placing instruction names into the non-blocking pipe.
#         - delete_instructions   A method for deleting the non-blocking pipe and any instructions inside.
#
#       `create_instructions` must accept a single argument, OPT, whose value is always 0, 1, or 2.
#       Evaluations of OPT should be interpreted as follows:
#         - 0: Output of any kind must be silenced using redirection `> /dev/null 2>&1`.
#         - 1: Status messages should be sent to stdout, all other output(s) silenced.
#         - 2: All output should be sent to stdout and `--verbose` options should be applied wherever possible.
#
# * * * BEGIN STANDARDIZED METHODS  * * * * * * * * * * * * * *

check_skip_tls_install() {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

add_tls_instructions_to_queue() {
  printf '%s\n' \
  tls_export_certificate_chain_passphrase \
  tls_create_tls_root_certs_dir \
  tls_create_tls_root_private_dir \
  tls_initialize_tls_root_serial_file \
  tls_initialize_tls_root_index_file \
  tls_copy_default_conf_as_root_conf \
  tls_export_root_ca_conf_path_env_var \
  tls_patch_line_45_root_ca_conf \
  tls_patch_line_51_root_ca_conf \
  tls_patch_line_53_root_ca_conf \
  tls_patch_line_77_root_ca_conf \
  tls_patch_line_108_root_ca_conf \
  tls_patch_line_131_root_ca_conf \
  tls_patch_line_136_root_ca_conf \
  tls_patch_line_141_root_ca_conf \
  tls_patch_line_160_root_ca_conf \
  tls_patch_line_161_root_ca_conf \
  tls_insert_new_line_110_root_ca_conf \
  tls_insert_new_line_140_root_ca_conf \
  tls_insert_new_line_261_root_ca_conf \
  tls_insert_new_line_262_root_ca_conf \
  tls_insert_new_line_263_root_ca_conf \
  tls_insert_new_line_264_root_ca_conf \
  tls_insert_new_line_265_root_ca_conf \
  tls_create_tls_intermediate_certs_dir \
  tls_create_tls_intermediate_csr_dir \
  tls_create_tls_intermediate_private_dir \
  tls_initialize_tls_intermediate_serial_file \
  tls_initialize_tls_intermediate_index_file \
  tls_initialize_tls_intermediate_crlnumber \
  tls_copy_root_conf_as_intermediate_conf \
  tls_export_intermediate_ca_conf_path_env_var \
  tls_patch_line_46_intermediate_ca_conf \
  tls_patch_line_54_intermediate_ca_conf \
  tls_patch_line_59_intermediate_ca_conf \
  tls_patch_line_84_intermediate_ca_conf \
  tls_generate_tls_root_private_cakey_pem \
  tls_generate_tls_root_certs_cacert_pem \
  tls_generate_tls_intermediate_private_cakey_pem \
  tls_generate_tls_intermediate_csr_csr_pem \
  tls_generate_tls_intermediate_certs_cacert_pem \
  tls_concatenate_certificate_bundle \
  tls_verify_certificate_bundle \
  tls_create_tls_intermediate_enc_dir \
  tls_encrypt_certificate_bundle \
  tls_unset_environment_variables \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

tls_export_certificate_chain_passphrase() {
  local PHRASE_LEN=$(jot -w %i -r 1 20 99)
  export CERTIFICATE_CHAIN_PASSPHRASE=$(tr -cd [[:alnum:]][[:punct:]] < /dev/random | fold -w${PHRASE_LEN} | head -n1)
  echo -e "\033[7;33mGenerated Secure Password in Env Var\033[0m" 1>&5
}
tls_create_tls_root_certs_dir() {
  mkdir -pm 0700 /tls/root/certs 1>&4
  echo -e "\033[7;33mCreated /tls/root/certs Directory\033[0m" 1>&5
}
tls_create_tls_root_private_dir() {
  mkdir -m 0700 /tls/root/private 1>&4
  echo -e "\033[7;33mCreated /tls/root/private Directory\033[0m" 1>&5
}
tls_initialize_tls_root_serial_file() {
  echo 01 > /tls/root/serial # 1>&4
  echo -e "\033[7;33mInitialized Root Serial File\033[0m" 1>&5
}
tls_initialize_tls_root_index_file() {
  touch /tls/root/index.txt 1>&4
  echo -e "\033[7;33mInitialized Root Index File\033[0m" 1>&5
}
tls_copy_default_conf_as_root_conf() {
  cp /etc/ssl/openssl.cnf /tls/root/openssl.cnf.root 1>&4
  echo -e "\033[7;33mCopied Default OpenSSL Config as Root Config\033[0m" 1>&5
}
tls_export_root_ca_conf_path_env_var() {
  export ROOT_CA_CONF_PATH=/tls/root/openssl.cnf.root 1>&4
  echo -e "\033[7;33mExported ROOT_CA_CONF_PATH Environment Variable\033[0m" 1>&5
}
tls_patch_line_45_root_ca_conf() {
  sed -i '45s/.\/demoCA/\/tls\/root/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 45 of Root Config\033[0m" 1>&5
}
tls_patch_line_51_root_ca_conf() {
  sed -i '51s/=\ \$dir\/newcerts/=\ \$dir\/certs/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 51 of Root Config\033[0m" 1>&5
}
tls_patch_line_53_root_ca_conf() {
  sed -i '53s/=\ \$dir\/cacert.pem/=\ \$dir\/certs\/cacert.pem/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 53 of Root Config\033[0m" 1>&5
}
tls_patch_line_77_root_ca_conf() {
  sed -i '77s/=\ default/=\ sha512/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 77 of Root Config\033[0m" 1>&5
}
tls_patch_line_108_root_ca_conf() {
  sed -i '108s/=\ 2048/=\ 4096/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 108 of Root Config\033[0m" 1>&5
}
tls_patch_line_131_root_ca_conf() {
  local COUNTRY_CODE="$(sed '1q;d' $HOME/.admin)"
  sed -i "131s/=\ AU/=\ ${COUNTRY_CODE}/" $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 131 of Root Config\033[0m" 1>&5
}
tls_patch_line_136_root_ca_conf() {
  local STATE_NAME="$(sed '2q;d' $HOME/.admin)"
  sed -i "136s/=\ Some-State/=\ ${STATE_NAME}/" $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 136 of Root Config\033[0m" 1>&5
}
tls_patch_line_141_root_ca_conf() {
  local ORGANIZATION_NAME="$(sed '3q;d' $HOME/.admin)"
  sed -i "141s/=\ Internet\ Widgits\ Pty\ Ltd/=\ ${ORGANIZATION_NAME}/" $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 141 of Root Config\033[0m" 1>&5
}
tls_patch_line_160_root_ca_conf() {
  # 128 bit when using character set [[:alnum:]][[:punct:]]
  sed -i '160s/=\ 4/=\ 20/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 160 of Root Config\033[0m" 1>&5
}
tls_patch_line_161_root_ca_conf() {
  # 256 bit when using character set [[:alnum:]][[:punct:]]
  sed -i '161s/=\ 20/=\ 39/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 161 of Root Config\033[0m" 1>&5
}
tls_insert_new_line_110_root_ca_conf() {
  sed -i '110i default_md = sha512' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 110 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_140_root_ca_conf() {
  local LOCATION_NAME="$(sed '4q;d' $HOME/.admin)"
  sed -i "140i localityName_default = ${LOCATION_NAME}" $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 140 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_261_root_ca_conf() {
  sed -i '261i [ v3_intermediate_ca ]' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 261 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_262_root_ca_conf() {
  sed -i '262i subjectKeyIdentifier = hash' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 262 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_263_root_ca_conf() {
  sed -i '263i authorityKeyIdentifier = keyid:always,issuer' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 263 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_264_root_ca_conf() {
  sed -i '264i basicConstraints = critical, CA:true, pathlen:0' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 264 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_265_root_ca_conf() {
  sed -i '265i keyUsage = critical, digitalSignature, cRLSign, keyCertSign' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 265 into Root Config\033[0m" 1>&5
}
tls_create_tls_intermediate_certs_dir() {
  mkdir -pm 0700 /tls/intermediate/certs 1>&4
  echo -e "\033[7;33mCreated /tls/intermediate/certs Directory\033[0m" 1>&5
}
tls_create_tls_intermediate_csr_dir() {
  mkdir -m 0700 /tls/intermediate/csr 1>&4
  echo -e "\033[7;33mCreated /tls/intermediate/csr Directory\033[0m" 1>&5
}
tls_create_tls_intermediate_private_dir() {
  mkdir -m 0700 /tls/intermediate/private 1>&4
  echo -e "\033[7;33mCreated /tls/intermediate/private Directory\033[0m" 1>&5
}
tls_initialize_tls_intermediate_serial_file() {
  echo 01 > /tls/intermediate/serial # 1>&4
  echo -e "\033[7;33mInitialized Intermediate Serial File\033[0m" 1>&5
}
tls_initialize_tls_intermediate_index_file() {
  touch /tls/intermediate/index.txt 1>&4
  echo -e "\033[7;33mInitialized Intermediate Index File\033[0m" 1>&5
}
tls_initialize_tls_intermediate_crlnumber() {
  echo 01 > /tls/intermediate/crlnumber # 1>&4
  echo -e "\033[7;33mInitialized Intermediate CRL Number\033[0m" 1>&5
}
tls_copy_root_conf_as_intermediate_conf() {
  cp /tls/root/openssl.cnf.root /tls/intermediate/openssl.cnf.intermediate 1>&4
  echo -e "\033[7;33mCopied Root OpenSSL Config as Intermediate Config\033[0m" 1>&5
}
tls_export_intermediate_ca_conf_path_env_var() {
  export INTERMEDIATE_CA_CONF_PATH=/tls/intermediate/openssl.cnf.intermediate 1>&4
  echo -e "\033[7;33mExported INTERMEDIATE_CA_CONF_PATH Environment Variable\033[0m" 1>&5
}
tls_patch_line_46_intermediate_ca_conf() {
  sed -i '46s/=\ \/tls\/root/=\ \/tls\/intermediate/' $INTERMEDIATE_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 46 of Intermediate Config\033[0m" 1>&5
}
tls_patch_line_54_intermediate_ca_conf() {
  sed -i '54s/=\ \$dir\/certs\/cacert.pem/=\ \$dir\/certs\/intermediate.cacert.pem/' $INTERMEDIATE_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 54 of Intermediate Config\033[0m" 1>&5
}
tls_patch_line_59_intermediate_ca_conf() {
  sed -i '59s/=\ \$dir\/private\/cakey.pem/=\ \$dir\/private\/intermediate.cakey.pem/' $INTERMEDIATE_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 59 of Intermediate Config\033[0m" 1>&5
}
tls_patch_line_84_intermediate_ca_conf() {
  sed -i '84s/=\ policy_match/=\ policy_anything/' $INTERMEDIATE_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 84 of Intermediate Config\033[0m" 1>&5
}
tls_generate_tls_root_private_cakey_pem() {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 genpkey \
  -out /tls/root/private/cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096 1>&4
  echo -e "\033[7;33mGenerated Root Private CAKEY PEM\033[0m" 1>&5
}
tls_generate_tls_root_certs_cacert_pem() {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 req \
  -new \
  -x509 \
  -sha512 \
  -days 3650 \
  -passin stdin \
  -config /tls/root/openssl.cnf.root \
  -extensions v3_ca \
  -key /tls/root/private/cakey.pem \
  -out /tls/root/certs/cacert.pem \
  -outform PEM \
  -batch 1>&4
  echo -e "\033[7;33mGenerated Root Certs CACERT PEM\033[0m" 1>&5
}
tls_generate_tls_intermediate_private_cakey_pem() {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 genpkey \
  -out /tls/intermediate/private/intermediate.cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096 1>&4
  echo -e "\033[7;33mGenerated Intermediate Private CAKEY PEM\033[0m" 1>&5
}
tls_generate_tls_intermediate_csr_csr_pem() {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 req \
  -new \
  -sha512 \
  -passin stdin \
  -config /tls/intermediate/openssl.cnf.intermediate \
  -key /tls/intermediate/private/intermediate.cakey.pem \
  -out /tls/intermediate/csr/intermediate.csr.pem \
  -outform PEM \
  -batch 1>&4
  echo -e "\033[7;33mGenerated Intermediate Csr CSR PEM\033[0m" 1>&5
}
tls_generate_tls_intermediate_certs_cacert_pem() {
  local ADMIN_CONTACT="$(sed '5q;d' $HOME/.admin)"
  local COUNTRY_CODE="$(sed '1q;d' $HOME/.admin)"
  local STATE_NAME="$(sed '6q;d' $HOME/.admin)"
  local LOCATION_NAME="$(sed '7q;d' $HOME/.admin)"
  local ORGANIZATION_NAME="$(sed '8q;d' $HOME/.admin)"
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 ca \
  -config tls/intermediate/openssl.cnf.intermediate \
  -extensions v3_intermediate_ca \
  -days 365 \
  -notext \
  -batch \
  -passin stdin \
  -subj "/CN=Alpine 3-10 Intermediate CA/emailAddress=${ADMIN_CONTACT}/C=${COUNTRY_CODE}/ST=${STATE_NAME}/L=${LOCATION_NAME}/O=${ORGANIZATION_NAME}" \
  -in /tls/intermediate/csr/intermediate.csr.pem \
  -out /tls/intermediate/certs/intermediate.cacert.pem 1>&4
  echo -e "\033[7;33mGenerated Intermediate Certs CACERT PEM\033[0m" 1>&5
}
tls_concatenate_certificate_bundle() {
  cat \
  /tls/intermediate/certs/intermediate.cacert.pem \
  /tls/root/certs/cacert.pem > /tls/intermediate/certs/ca-chain-bundle.cert.pem 1>&4
  echo -e "\033[7;33mConcatenated Certificate Bundle\033[0m" 1>&5
}
tls_verify_certificate_bundle() {
  $OPENSSL_V111 verify \
  -CAfile \
  /tls/root/certs/cacert.pem \
  /tls/intermediate/certs/ca-chain-bundle.cert.pem 1>&4
  echo -e "\033[7;33mVerified Certificate Bundle Using OpenSSL\033[0m" 1>&5
}
tls_create_tls_intermediate_enc_dir() {
  mkdir /tls/intermediate/enc 1>&4
  echo -e "\033[7;33mCreated Enc Directory under /tls/intermediate\033[0m" 1>&5
}
tls_encrypt_to_external() {
  local TLS_WRAP_PAD_PAYLOAD="$($OPENSSL_V111 rand 32)"
  local TLS_WRAP_PAD_EPHEMERAL="$($OPENSSL_V111 rand 32)"
  local TLS_WRAP_PAD_PRIVATE="$( \
    $OPENSSL_V111 genpkey \
    -outform PEM \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  local TLS_WRAP_PAD_PUBLIC="$( \
    echo ${TLS_WRAP_PAD_PRIVATE} | base64 -d | \
    $OPENSSL_V111 rsa \
    -inform PEM \
    -outform PEM \
    -pubout | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"

  # Wrap the certificate chain file in the payload.
  cat /tls/intermediate/certs/ca-chain-bundle.cert.pem | \
  $OPENSSL_V111 enc -id-aes256-wrap-pad \
  -K $(echo "${TLS_WRAP_PAD_PAYLOAD}" | hexdump -v -e '/1 "%02X"') \
  -iv A65959A6 \
  -out /tls/intermediate/enc/ca-chain-bundle.wrapped 1>&4
  
  # Wrap the payload in the ephemeral.
  local TLS_WRAP_PAD_PAYLOAD_WRAPPED="$( \
    echo "${TLS_WRAP_PAD_PAYLOAD}" | \
    $OPENSSL_V111 enc -id-aes256-wrap-pad \
    -K $(echo "${TLS_WRAP_PAD_EPHEMERAL}" | hexdump -v -e '/1 "%02X"') \
    -iv A65959A6 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  
  # Wrap the ephemeral in the public key.
  mkfifo tls_public_named_pipe
  ( echo "${TLS_WRAP_PAD_PUBLIC}" > tls_public_named_pipe & )
  #
  local TLS_WRAP_PAD_EPHEMERAL_WRAPPED="$( \
    echo "${TLS_WRAP_PAD_EPHEMERAL}" | \
    $OPENSSL_V111 pkeyutl \
    -encrypt \
    -pubin -inkey tls_public_named_pipe \
    -pkeyopt rsa_padding_mode:oaep \
    -pkeyopt rsa_oaep_md:sha1 \
    -pkeyopt rsa_mgf1_md:sha1 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  #
  ( rm -f tls_public_named_pipe )

  # Concatenate the ephemeral wrapped and payload wrapped into rsa aes wrapped.
  echo "${TLS_WRAP_PAD_EPHEMERAL_WRAPPED}" >> /tls/intermediate/enc/ca-chain-bundle.rsa-aes.wrapped 1>&4
  echo "${TLS_WRAP_PAD_PAYLOAD_WRAPPED}" >> /tls/intermediate/enc/ca-chain-bundle.rsa-aes.wrapped 1>&4
  
  # Export the private key and move the root certificate to external.
  printf '%s\n' ${TLS_WRAP_PAD_PRIVATE} > /external/tls-intermediate-ca-chain-bundle.private.key 1>&4
  mv /tls/root/ /external/root/ 1>&4
  echo -e "\033[7;33mEncrypted Data at Rest and Moved Files to External\033[0m" 1>&5
}
tls_unset_environment_variables() {
  unset CERTIFICATE_CHAIN_PASSPHRASE
  unset ADMIN_CONTACT
  unset COUNTRY_CODE
  unset STATE_NAME
  unset LOCATION_NAME
  unset ORGANIZATION_NAME
  unset ROOT_CA_CONF_PATH
  unset INTERMEDIATE_CA_CONF_PATH
  echo -e "\033[7;33mAll Environment Variables Now Unset\033[0m" 1>&5
}