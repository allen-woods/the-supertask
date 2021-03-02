#!/bin/sh

# Dependencies:
#   - OS X Mojave 10.14.6+
#   - OpenSSL 1.1.1j
#     - Location: /usr/local/etc/openssl@1.1
call_instructions() {
  tls_export_lc_ctype && \
  tls_generate_random_password && \
  tls_create_tls_root_certs_dir && \
  tls_create_tls_root_private_dir && \
  tls_initialize_tls_root_serial_file && \
  tls_initialize_tls_root_index_file && \
  tls_copy_default_conf_as_root_conf && \
  tls_export_root_ca_conf_path_env_var && \
  tls_patch_line_46_root_ca_conf && \
  tls_patch_line_52_root_ca_conf && \
  tls_patch_line_54_root_ca_conf && \
  tls_patch_line_79_root_ca_conf && \
  tls_patch_line_110_root_ca_conf && \
  tls_patch_line_133_root_ca_conf && \
  tls_patch_line_138_root_ca_conf && \
  tls_patch_line_143_root_ca_conf && \
  tls_patch_line_162_root_ca_conf && \
  tls_patch_line_163_root_ca_conf && \
  tls_insert_new_line_114_root_ca_conf && \
  tls_insert_new_line_142_root_ca_conf && \
  tls_insert_new_line_263_root_ca_conf && \
  tls_insert_new_line_264_root_ca_conf && \
  tls_insert_new_line_265_root_ca_conf && \
  tls_insert_new_line_266_root_ca_conf && \
  tls_insert_new_line_267_root_ca_conf && \
  tls_create_tls_intermediate_certs_dir && \
  tls_create_tls_intermediate_csr_dir && \
  tls_create_tls_intermediate_private_dir && \
  tls_initialize_tls_intermediate_serial_file && \
  tls_initialize_tls_intermediate_index_file && \
  tls_initialize_tls_intermediate_crlnumber && \
  tls_copy_root_conf_as_intermediate_conf && \
  tls_export_intermediate_ca_conf_path_env_var && \
  tls_patch_line_46_intermediate_ca_conf && \
  tls_patch_line_54_intermediate_ca_conf && \
  tls_patch_line_59_intermediate_ca_conf && \
  tls_patch_line_85_intermediate_ca_conf && \
  tls_generate_tls_root_private_cakey_pem && \
  tls_generate_tls_root_certs_cacert_pem && \
  tls_generate_tls_intermediate_private_cakey_pem && \
  tls_generate_tls_intermediate_csr_csr_pem && \
  tls_generate_tls_intermediate_certs_cacert_pem && \
  tls_persist_cert_chain_phrase && \
  unset_environment_variables
}

tls_export_lc_ctype() {
  export LC_CTYPE=C
}
tls_generate_random_password() {
  local phrase_len=$(jot -w %i -r 1 20 99)
  local phrase=$(tr -cd '[:graph:]' < /dev/urandom | fold -w${phrase_len} | head -n1)
  export CERT_CHAIN_PHRASE=$(echo $phrase)
  echo -e "\033[7;33mGenerated Secure Password as Env Var\033[0m"
}
tls_create_tls_root_certs_dir() {
  mkdir -pm 0755 ${CONTAINER_PATH}/tls/root/certs
  echo -e "\033[7;33mCreated ${CONTAINER_PATH}/tls/root/certs Directory\033[0m"
}
tls_create_tls_root_private_dir() {
  mkdir -m 0755 ${CONTAINER_PATH}/tls/root/private
  echo -e "\033[7;33mCreated ${CONTAINER_PATH}/tls/root/private Directory\033[0m"
}
tls_initialize_tls_root_serial_file() {
  echo 01 > ${CONTAINER_PATH}/tls/root/serial #
  echo -e "\033[7;33mInitialized Root Serial File\033[0m"
}
tls_initialize_tls_root_index_file() {
  touch ${CONTAINER_PATH}/tls/root/index.txt
  echo -e "\033[7;33mInitialized Root Index File\033[0m"
}
tls_copy_default_conf_as_root_conf() {
  cp /usr/local/etc/openssl@1.1/openssl.cnf ${CONTAINER_PATH}/tls/root/openssl.cnf.root
  echo -e "\033[7;33mCopied Default OpenSSL Config as Root Config\033[0m"
}
tls_export_root_ca_conf_path_env_var() {
  export ROOT_CA_CONF_PATH=${CONTAINER_PATH}/tls/root/openssl.cnf.root
  echo -e "\033[7;33mExported ROOT_CA_CONF_PATH Environment Variable\033[0m"
}
tls_patch_line_46_root_ca_conf() {
  sed -i'' -e '46s#./demoCA#'"${CONTAINER_PATH}"'/tls/root#' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 46 of Root Config\033[0m"
}
tls_patch_line_52_root_ca_conf() {
  sed -i'' -e '52s#=\ \$dir/newcerts#=\ \$dir/certs#' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 52 of Root Config\033[0m"
}
tls_patch_line_54_root_ca_conf() {
  sed -i'' -e '54s#=\ \$dir/cacert.pem#=\ \$dir/certs/cacert.pem#' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 54 of Root Config\033[0m"
}
tls_patch_line_79_root_ca_conf() {
  sed -i'' -e '79s#=\ default#=\ sha512#' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 79 of Root Config\033[0m"
}
tls_patch_line_110_root_ca_conf() {
  sed -i'' -e '110s#=\ 2048#=\ 4096#' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 110 of Root Config\033[0m"
}
tls_patch_line_133_root_ca_conf() {
  local COUNTRY_CODE="$(sed '1q;d' ${CONTAINER_PATH}/tls/.admin)"
  sed -i'' -e "133s#=\ AU#=\ ${COUNTRY_CODE}#" $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 133 of Root Config\033[0m"
}
tls_patch_line_138_root_ca_conf() {
  local STATE_NAME="$(sed '2q;d' ${CONTAINER_PATH}/tls/.admin)"
  sed -i'' -e "138s#=\ Some-State#=\ ${STATE_NAME}#" $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 138 of Root Config\033[0m"
}
tls_patch_line_143_root_ca_conf() {
  local ORGANIZATION_NAME="$(sed '3q;d' ${CONTAINER_PATH}/tls/.admin)"
  sed -i'' -e "143s#=\ Internet\ Widgits\ Pty\ Ltd#=\ ${ORGANIZATION_NAME}#" $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 143 of Root Config\033[0m"
}
tls_patch_line_162_root_ca_conf() {
  sed -i'' -e '162s#=\ 4#=\ 20#' $ROOT_CA_CONF_PATH # 128 bit, [:graph:]
  echo -e "\033[7;33mPatched Line 162 of Root Config\033[0m"
}
tls_patch_line_163_root_ca_conf() {
  sed -i'' -e '163s#=\ 20#=\ 39#' $ROOT_CA_CONF_PATH # 256 bit, [:graph:]
  echo -e "\033[7;33mPatched Line 163 of Root Config\033[0m"
}
tls_insert_new_line_114_root_ca_conf() {
  sed -i'' -e '114i\
   default_md = sha512
   ' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mInserted New Line 114 into Root Config\033[0m"
}
tls_insert_new_line_142_root_ca_conf() {
  local LOCATION_NAME="$(sed '4q;d' ${CONTAINER_PATH}/tls/.admin)"
  sed -i'' -e '142i\
   localityName_default = '"${LOCATION_NAME}"'
   ' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mInserted New Line 142 into Root Config\033[0m"
}
tls_insert_new_line_263_root_ca_conf() {
  sed -i'' -e '263i\
   [ v3_intermediate_ca ]
   ' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mInserted New Line 263 into Root Config\033[0m"
}
tls_insert_new_line_264_root_ca_conf() {
  sed -i'' -e '264i\
   subjectKeyIdentifier = hash
   ' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mInserted New Line 264 into Root Config\033[0m"
}
tls_insert_new_line_265_root_ca_conf() {
  sed -i'' -e '265i\
   authorityKeyIdentifier = keyid:always,issuer
   ' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mInserted New Line 265 into Root Config\033[0m"
}
tls_insert_new_line_266_root_ca_conf() {
  sed -i'' -e '266i\
   basicConstraints = critical, CA:true, pathlen:0
   ' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mInserted New Line 266 into Root Config\033[0m"
}
tls_insert_new_line_267_root_ca_conf() {
  sed -i'' -e '267a\
   keyUsage = critical, digitalSignature, cRLSign, keyCertSign
   ' $ROOT_CA_CONF_PATH
  echo -e "\033[7;33mInserted New Line 267 into Root Config\033[0m"
}
tls_create_tls_intermediate_certs_dir() {
  mkdir -pm 0755 ${CONTAINER_PATH}/tls/intermediate/certs
  echo -e "\033[7;33mCreated ${CONTAINER_PATH}/tls/intermediate/certs Directory\033[0m"
}
tls_create_tls_intermediate_csr_dir() {
  mkdir -m 0755 ${CONTAINER_PATH}/tls/intermediate/csr
  echo -e "\033[7;33mCreated ${CONTAINER_PATH}/tls/intermediate/csr Directory\033[0m"
}
tls_create_tls_intermediate_private_dir() {
  mkdir -m 0755 ${CONTAINER_PATH}/tls/intermediate/private
  echo -e "\033[7;33mCreated ${CONTAINER_PATH}/tls/intermediate/private Directory\033[0m"
}
tls_initialize_tls_intermediate_serial_file() {
  echo 01 > ${CONTAINER_PATH}/tls/intermediate/serial #
  echo -e "\033[7;33mInitialized Intermediate Serial File\033[0m"
}
tls_initialize_tls_intermediate_index_file() {
  touch ${CONTAINER_PATH}/tls/intermediate/index.txt
  echo -e "\033[7;33mInitialized Intermediate Index File\033[0m"
}
tls_initialize_tls_intermediate_crlnumber() {
  echo 01 > ${CONTAINER_PATH}/tls/intermediate/crlnumber #
  echo -e "\033[7;33mInitialized Intermediate CRL Number\033[0m"
}
tls_copy_root_conf_as_intermediate_conf() {
  cp $ROOT_CA_CONF_PATH ${CONTAINER_PATH}/tls/intermediate/openssl.cnf.intermediate
  echo -e "\033[7;33mCopied Root OpenSSL Config as Intermediate Config\033[0m"
}
tls_export_intermediate_ca_conf_path_env_var() {
  export INTERMEDIATE_CA_CONF_PATH=${CONTAINER_PATH}/tls/intermediate/openssl.cnf.intermediate
  echo -e "\033[7;33mExported INTERMEDIATE_CA_CONF_PATH Environment Variable\033[0m"
}
tls_patch_line_46_intermediate_ca_conf() {
  sed -i'' -e '46s#root#intermediate#' $INTERMEDIATE_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 46 of Root Config\033[0m"
}
tls_patch_line_54_intermediate_ca_conf() {
  sed -i'' -e '54s#=\ \$dir/certs/cacert.pem#=\ \$dir/certs/intermediate.cacert.pem#' $INTERMEDIATE_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 54 of Intermediate Config\033[0m"
}
tls_patch_line_59_intermediate_ca_conf() {
  sed -i'' -e '59s#=\ \$dir/private/cakey.pem#=\ \$dir/private/intermediate.cakey.pem#' $INTERMEDIATE_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 59 of Intermediate Config\033[0m"
}
tls_patch_line_85_intermediate_ca_conf() {
  sed -i'' -e '85s#=\ policy_match#=\ policy_anything#' $INTERMEDIATE_CA_CONF_PATH
  echo -e "\033[7;33mPatched Line 84 of Intermediate Config\033[0m"
}
tls_generate_tls_root_private_cakey_pem() {
  echo $CERT_CHAIN_PHRASE | \
  openssl genpkey \
  -out ${CONTAINER_PATH}/tls/root/private/cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
  echo -e "\033[7;33mGenerated Root Private CAKEY PEM\033[0m"
}
tls_generate_tls_root_certs_cacert_pem() {
  echo $CERT_CHAIN_PHRASE | \
  openssl req \
  -new \
  -x509 \
  -sha512 \
  -days 3650 \
  -passin stdin \
  -config ${ROOT_CA_CONF_PATH} \
  -extensions v3_ca \
  -key ${CONTAINER_PATH}/tls/root/private/cakey.pem \
  -out ${CONTAINER_PATH}/tls/root/certs/cacert.pem \
  -outform PEM \
  -batch
  echo -e "\033[7;33mGenerated Root Certs CACERT PEM\033[0m"
}
tls_generate_tls_intermediate_private_cakey_pem() {
  echo $CERT_CHAIN_PHRASE | \
  openssl genpkey \
  -out ${CONTAINER_PATH}/tls/intermediate/private/intermediate.cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
  echo -e "\033[7;33mGenerated Intermediate Private CAKEY PEM\033[0m"
}
tls_generate_tls_intermediate_csr_csr_pem() {
  echo $CERT_CHAIN_PHRASE | \
  openssl req \
  -new \
  -sha512 \
  -passin stdin \
  -config ${INTERMEDIATE_CA_CONF_PATH} \
  -key ${CONTAINER_PATH}/tls/intermediate/private/intermediate.cakey.pem \
  -out ${CONTAINER_PATH}/tls/intermediate/csr/intermediate.csr.pem \
  -outform PEM \
  -batch
  echo -e "\033[7;33mGenerated Intermediate Csr CSR PEM\033[0m"
}
tls_generate_tls_intermediate_certs_cacert_pem() {
  local ADMIN_CONTACT="$(sed '5q;d' ${CONTAINER_PATH}/tls/.admin)"
  local COUNTRY_CODE="$(sed '1q;d' ${CONTAINER_PATH}/tls/.admin)"
  local STATE_NAME="$(sed '2q;d' ${CONTAINER_PATH}/tls/.admin)"
  local LOCATION_NAME="$(sed '4q;d' ${CONTAINER_PATH}/tls/.admin)"
  local ORGANIZATION_NAME="$(sed '3q;d' ${CONTAINER_PATH}/tls/.admin)"
  echo $CERT_CHAIN_PHRASE | \
  openssl ca \
  -config ${ROOT_CA_CONF_PATH} \
  -extensions v3_intermediate_ca \
  -days 365 \
  -batch \
  -passin stdin \
  -subj "/CN=Alpine 3-10 Intermediate CA/emailAddress=${ADMIN_CONTACT}/C=${COUNTRY_CODE}/ST=${STATE_NAME}/L=${LOCATION_NAME}/O=${ORGANIZATION_NAME}" \
  -in ${CONTAINER_PATH}/tls/intermediate/csr/intermediate.csr.pem \
  -out ${CONTAINER_PATH}/tls/intermediate/certs/intermediate.cacert.pem
  echo -e "\033[7;33mGenerated Intermediate Certs CACERT PEM\033[0m"
}
tls_persist_cert_chain_phrase() {
  echo $CERT_CHAIN_PHRASE | base64 > ${CONTAINER_PATH}/tls/.phrase
  echo -e "\033[7;33mPersisted Cert Chain Phrase\033[0m"
}
unset_environment_variables() {
  unset CERT_CHAIN_PHRASE
  unset ADMIN_CONTACT
  unset COUNTRY_CODE
  unset STATE_NAME
  unset LOCATION_NAME
  unset ORGANIZATION_NAME
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

# NOTE:
# These Commented functions are retained for completeness where they originally appeared.
# Use of the commented functions causes catastrophic failure of DieHarder's `make install` process,
# so I'm standardizing their non-use for consistency.
#
# patch_etc_apk_repositories() {
#   sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories
#   echo -e "\033[7;33mPatched Alpine to Latest Stable\033[0m" # These are status messages that have fg/bg commands (colors).
# }
# apk_update() {
#   apk update
#   echo -e "\033[7;33mApk Update\033[0m"
# }
# apk_static_upgrade_simulate() {
#   apk.static upgrade --no-self-upgrade --available --simulate
#   echo -e "\033[7;33mChecked for Problems in Alpine Upgrade\033[0m"
# }
# apk_static_upgrade() {
#   apk.static upgrade --no-self-upgrade --available
#   echo -e "\033[7;33mProceeded with Alpine Upgrade\033[0m"
# }