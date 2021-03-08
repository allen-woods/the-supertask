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
  tls_source_shrc_openssl_v111 \
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
  tls_change_dir_to_tls_root \
  tls_generate_tls_root_private_cakey_pem \
  tls_generate_tls_root_certs_cacert_pem \
  tls_change_dir_to_tls_intermediate \
  tls_generate_tls_intermediate_private_cakey_pem \
  tls_generate_tls_intermediate_csr_csr_pem \
  tls_generate_tls_intermediate_certs_cacert_pem \
  tls_unset_environment_variables \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

tls_apk_add_busybox_static() {
  apk add busybox-static apk-tools-static && apk.static add openssl1>&4
  echo -e "\033[7;33mAdded BusyBox Static Tools\033[0m" 1>&5
}
tls_apk_add_apk_tools_static() {
  apk add apk-tools-static 1>&4
  echo -e "\033[7;33mAdded APK Static Tools\033[0m" 1>&5
}
tls_apk_static_add_openssl() {
  apk.static add openssl 1>&4
  echo -e "\033[7;33mAdded OpenSSL\033[0m" 1>&5
}
tls_apk_static_add_outils_jot() {
  apk.static add outils-jot 1>&4
  echo -e "\033[7;33mAdded OUtils Jot\033[0m" 1>&5
}
tls_source_shrc_openssl_v111() {
  . $HOME/.shrc 1>&4
  echo -e "\033[7;33mSourced OPENSSL_V111 From SHRC File\033[0m" 1>&5
}
tls_export_certificate_chain_passphrase() {
  local PHRASE_LEN=$(jot -w %i -r 1 20 99)
  # Use blocking RNG source for better entropy.
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
  sed -i '131s/=\ AU/=\ US/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 131 of Root Config\033[0m" 1>&5
}
tls_patch_line_136_root_ca_conf() {
  sed -i '136s/=\ Some-State/=\ Washington/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 136 of Root Config\033[0m" 1>&5
}
tls_patch_line_141_root_ca_conf() {
  sed -i '141s/=\ Internet\ Widgits\ Pty\ Ltd/=\ The\ Supertask/' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mPatched Line 141 of Root Config\033[0m" 1>&5
}
tls_patch_line_160_root_ca_conf() {
  sed -i '160s/=\ 4/=\ 20/' $ROOT_CA_CONF_PATH 1>&4 # 128 bit, [[:alnum:]][[:punct:]]
  echo -e "\033[7;33mPatched Line 160 of Root Config\033[0m" 1>&5
}
tls_patch_line_161_root_ca_conf() {
  sed -i '161s/=\ 20/=\ 39/' $ROOT_CA_CONF_PATH 1>&4 # 256 bit, [[:alnum:]][[:punct:]]
  echo -e "\033[7;33mPatched Line 161 of Root Config\033[0m" 1>&5
}
tls_insert_new_line_110_root_ca_conf() {
  sed -i '109a default_md = sha512' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 110 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_140_root_ca_conf() {
  sed -i '139a localityName_default = SEATTLE' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 140 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_261_root_ca_conf() {
  sed -i '260a [ v3_intermediate_ca ]' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 261 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_262_root_ca_conf() {
  sed -i '261a subjectKeyIdentifier = hash' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 262 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_263_root_ca_conf() {
  sed -i '262a authorityKeyIdentifier = keyid:always,issuer' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 263 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_264_root_ca_conf() {
  sed -i '263a basicConstraints = critical, CA:true, pathlen:0' $ROOT_CA_CONF_PATH 1>&4
  echo -e "\033[7;33mInserted New Line 264 into Root Config\033[0m" 1>&5
}
tls_insert_new_line_265_root_ca_conf() {
  sed -i '264a keyUsage = critical, digitalSignature, cRLSign, keyCertSign' $ROOT_CA_CONF_PATH 1>&4
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
tls_change_dir_to_tls_root() {
  cd /tls/root 1>&4
  echo -e "\033[7;33mChanged Current Directory to /tls/root\033[0m" 1>&5
}
tls_generate_tls_root_private_cakey_pem() {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 genpkey \
  -out ./private/cakey.pem \
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
  -config ./openssl.cnf.root \
  -extensions v3_ca \
  -key ./private/cakey.pem \
  -out ./certs/cacert.pem \
  -outform PEM \
  -batch 1>&4
  echo -e "\033[7;33mGenerated Root Certs CACERT PEM\033[0m" 1>&5
}
tls_change_dir_to_tls_intermediate() {
  cd /tls/intermediate 1>&4
}
tls_generate_tls_intermediate_private_cakey_pem() {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 genpkey \
  -out ./private/intermediate.cakey.pem \
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
  -config ./openssl.cnf.intermediate \
  -key ./private/intermediate.cakey.pem \
  -out ./csr/intermediate.csr.pem \
  -outform PEM \
  -batch 1>&4
  echo -e "\033[7;33mGenerated Intermediate Csr CSR PEM\033[0m" 1>&5
}
tls_generate_tls_intermediate_certs_cacert_pem() {
  # TODO: Place all identifying information inside of the .admin file, export using sed '##q;d' of desired line
  local ADMIN_CONTACT=$(cat $HOME/.admin | head -n1)
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  $OPENSSL_V111 ca \
  -config ./openssl.cnf.intermediate \
  -extensions v3_intermediate_ca \
  -days 365 \
  -notext \
  -batch \
  -passin stdin \
  -subj "/CN=Alpine 3-12 Intermediate CA/emailAddress=${ADMIN_CONTACT}/C=US/ST=Washington/L=Seattle/O=The Supertask" \
  -in ./csr/intermediate.csr.pem \
  -out ./certs/intermediate.cacert.pem 1>&4
  echo -e "\033[7;33mGenerated Intermediate Certs CACERT PEM\033[0m" 1>&5
}
tls_unset_environment_variables() {
  # TODO: Unset all env vars used.
  unset ADMIN_CONTACT
  unset ROOT_CA_CONF_PATH
  unset INTERMEDIATE_CA_CONF_PATH
  echo -e "\033[7;33mAll Environment Variables Now Unset\033[0m"
}

# # Certificate bundle.
# #
# # NOTE:
# # These functions will not be used per Vault's advice to only
# # provide the intermediate cert to Vault's config, not the root
# # cert.
# #
# # This means we can't pass a bundle to Vault safely.
# # Preserved here for completeness only.
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