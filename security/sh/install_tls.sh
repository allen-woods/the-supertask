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

check_skip_tls_install () {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

add_tls_instructions_to_queue () {
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
  tls_patch_line_45_intermediate_ca_conf \
  tls_patch_line_54_intermediate_ca_conf \
  tls_patch_line_58_intermediate_ca_conf \
  tls_patch_line_83_intermediate_ca_conf \
  tls_generate_tls_root_private_cakey_pem \
  tls_generate_tls_root_certs_cacert_pem \
  tls_generate_tls_intermediate_private_cakey_pem \
  tls_generate_tls_intermediate_csr_csr_pem \
  tls_generate_tls_intermediate_certs_cacert_pem \
  tls_concatenate_certificate_bundle \
  tls_verify_certificate_bundle \
  tls_unset_environment_variables \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

tls_apk_add_packages () {
  local ARG=$1
  if [ -z "$( echo -n ${ARG} | sed 's|[0-9]\{1,\}||g' )" ]; then
    [ $ARG -eq 0 ] && [ -z "${APK_FLAGS}" ] && local APK_FLAGS='--quiet --no-progress'
    [ $ARG -eq 2 ] && [ -z "${APK_FLAGS}" ] && local APK_FLAGS='--verbose'
  fi
  apk "${APK_FLAGS}" update
  apk --no-cache "${APK_FLAGS}" add \
    busybox-static=1.32.1-r6 \
    apk-tools-static=2.12.7-r0
  apk.static --no-cache "${APK_FLAGS}" add \
    outils-jot=0.9-r0
}

tls_export_certificate_chain_passphrase () {
  local PHRASE_LEN=$(jot -w %i -r 1 24 96)
  export CERTIFICATE_CHAIN_PASSPHRASE=$( utf8_passphrase "${PHRASE_LEN}" )
}
tls_create_tls_root_certs_dir () {
  mkdir -pm 0700 /to_host/tls/root/certs
}
tls_create_tls_root_private_dir () {
  mkdir -m 0700 /to_host/tls/root/private
}
tls_initialize_tls_root_serial_file () {
  echo 01 > /to_host/tls/root/serial
}
tls_initialize_tls_root_index_file () {
  touch /to_host/tls/root/index.txt
}
tls_copy_default_conf_as_root_conf () {
  cp /etc/ssl/openssl.cnf /to_host/tls/root/openssl.cnf.root
}
tls_export_root_ca_conf_path_env_var () {
  export ROOT_CA_CONF_PATH=/to_host/tls/root/openssl.cnf.root
}
tls_patch_line_45_root_ca_conf () {
  sed -i '45s/.\/demoCA/\/to_host\/tls\/root/' $ROOT_CA_CONF_PATH
}
tls_patch_line_51_root_ca_conf () {
  sed -i '51s/=\ \$dir\/newcerts/=\ \$dir\/certs/' $ROOT_CA_CONF_PATH
}
tls_patch_line_53_root_ca_conf () {
  sed -i '53s/=\ \$dir\/cacert.pem/=\ \$dir\/certs\/cacert.pem/' $ROOT_CA_CONF_PATH
}
tls_patch_line_77_root_ca_conf () {
  sed -i '77s/=\ default/=\ sha512/' $ROOT_CA_CONF_PATH
}
tls_patch_line_108_root_ca_conf () {
  sed -i '108s/=\ 2048/=\ 4096/' $ROOT_CA_CONF_PATH
}
tls_patch_line_131_root_ca_conf () {
  local COUNTRY_CODE="$(sed '1q;d' $HOME/.admin)"
  sed -i "131s/=\ AU/=\ ${COUNTRY_CODE}/" $ROOT_CA_CONF_PATH
}
tls_patch_line_136_root_ca_conf () {
  local STATE_NAME="$(sed '2q;d' $HOME/.admin)"
  sed -i "136s/=\ Some-State/=\ ${STATE_NAME}/" $ROOT_CA_CONF_PATH
}
tls_patch_line_141_root_ca_conf () {
  local ORGANIZATION_NAME="$(sed '3q;d' $HOME/.admin)"
  sed -i "141s/=\ Internet\ Widgits\ Pty\ Ltd/=\ ${ORGANIZATION_NAME}/" $ROOT_CA_CONF_PATH
}
tls_patch_line_160_root_ca_conf () {
  # 128 bit when using character set [[:alnum:]][[:punct:]]
  sed -i '160s/=\ 4/=\ 20/' $ROOT_CA_CONF_PATH
}
tls_patch_line_161_root_ca_conf () {
  # 256 bit when using character set [[:alnum:]][[:punct:]]
  sed -i '161s/=\ 20/=\ 39/' $ROOT_CA_CONF_PATH
}
tls_insert_new_line_110_root_ca_conf () {
  sed -i '110i default_md = sha512' $ROOT_CA_CONF_PATH
}
tls_insert_new_line_140_root_ca_conf () {
  local LOCATION_NAME="$(sed '4q;d' $HOME/.admin)"
  sed -i "140i localityName_default = ${LOCATION_NAME}" $ROOT_CA_CONF_PATH
}
tls_insert_new_line_261_root_ca_conf () {
  sed -i '261i [ v3_intermediate_ca ]' $ROOT_CA_CONF_PATH
}
tls_insert_new_line_262_root_ca_conf () {
  sed -i '262i subjectKeyIdentifier=hash' $ROOT_CA_CONF_PATH
}
tls_insert_new_line_263_root_ca_conf () {
  sed -i '263i authorityKeyIdentifier=keyid:always,issuer' $ROOT_CA_CONF_PATH
}
tls_insert_new_line_264_root_ca_conf () {
  sed -i '264i basicConstraints = critical,CA:true,pathlen:0' $ROOT_CA_CONF_PATH
}
tls_insert_new_line_265_root_ca_conf () {
  sed -i '265i keyUsage = critical,digitalSignature,cRLSign,keyCertSign' $ROOT_CA_CONF_PATH
  # Insert an empty line for padding in conf file.
  sed -i '266i  ' $ROOT_CA_CONF_PATH
}
tls_create_tls_intermediate_certs_dir () {
  mkdir -pm 0700 /tls/intermediate/certs
}
tls_create_tls_intermediate_csr_dir () {
  mkdir -m 0700 /tls/intermediate/csr
}
tls_create_tls_intermediate_private_dir () {
  mkdir -m 0700 /tls/intermediate/private
}
tls_initialize_tls_intermediate_serial_file () {
  echo 01 > /tls/intermediate/serial
}
tls_initialize_tls_intermediate_index_file () {
  touch /tls/intermediate/index.txt
}
tls_initialize_tls_intermediate_crlnumber () {
  echo 01 > /tls/intermediate/crlnumber
}
tls_copy_root_conf_as_intermediate_conf () {
  cp /to_host/tls/root/openssl.cnf.root /tls/intermediate/openssl.cnf.intermediate
}
tls_export_intermediate_ca_conf_path_env_var () {
  export INTERMEDIATE_CA_CONF_PATH=/tls/intermediate/openssl.cnf.intermediate
}
tls_patch_line_45_intermediate_ca_conf () {
  sed -i '45s/=\ \/tls\/root/=\ \/tls\/intermediate/' $INTERMEDIATE_CA_CONF_PATH
}
tls_patch_line_54_intermediate_ca_conf () {
  sed -i '53s/=\ \$dir\/certs\/cacert.pem/=\ \$dir\/certs\/intermediate.cacert.pem/' $INTERMEDIATE_CA_CONF_PATH
}
tls_patch_line_58_intermediate_ca_conf () {
  sed -i '58s/=\ \$dir\/private\/cakey.pem/=\ \$dir\/private\/intermediate.cakey.pem/' $INTERMEDIATE_CA_CONF_PATH
}
tls_patch_line_83_intermediate_ca_conf () {
  sed -i '83s/=\ policy_match/=\ policy_anything/' $INTERMEDIATE_CA_CONF_PATH
}
tls_generate_tls_root_private_cakey_pem () {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  aes-wrap genpkey \
  -out /to_host/tls/root/private/cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
}
tls_generate_tls_root_certs_cacert_pem () {
  ADMIN_CONTACT="$(sed '5q;d' $HOME/.admin)"
  COUNTRY_CODE="$(sed '1q;d' $HOME/.admin)"
  STATE_NAME="$(sed '6q;d' $HOME/.admin)"
  LOCATION_NAME="$(sed '7q;d' $HOME/.admin)"
  ORGANIZATION_NAME="$(sed '8q;d' $HOME/.admin)"
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  aes-wrap req \
  -new \
  -x509 \
  -sha512 \
  -days 3650 \
  -passin stdin \
  -config /to_host/tls/root/openssl.cnf.root \
  -extensions v3_ca \
  -subj "/CN=Alpine 3-13/emailAddress=${ADMIN_CONTACT}/C=${COUNTRY_CODE}/ST=${STATE_NAME}/L=${LOCATION_NAME}/O=${ORGANIZATION_NAME}" \
  -key /to_host/tls/root/private/cakey.pem \
  -out /to_host/tls/root/certs/cacert.pem \
  -outform PEM \
  -batch
}
tls_generate_tls_intermediate_private_cakey_pem () {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  aes-wrap genpkey \
  -out /tls/intermediate/private/intermediate.cakey.pem \
  -outform PEM \
  -pass stdin \
  -aes256 \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096
}
tls_generate_tls_intermediate_csr_csr_pem () {
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  aes-wrap req \
  -new \
  -sha512 \
  -passin stdin \
  -config /tls/intermediate/openssl.cnf.intermediate \
  -key /tls/intermediate/private/intermediate.cakey.pem \
  -out /tls/intermediate/csr/intermediate.csr.pem \
  -outform PEM \
  -batch
}
tls_generate_tls_intermediate_certs_cacert_pem () {
  ADMIN_CONTACT="$(sed '5q;d' $HOME/.admin)"
  COUNTRY_CODE="$(sed '1q;d' $HOME/.admin)"
  STATE_NAME="$(sed '6q;d' $HOME/.admin)"
  LOCATION_NAME="$(sed '7q;d' $HOME/.admin)"
  ORGANIZATION_NAME="$(sed '8q;d' $HOME/.admin)"
  echo ${CERTIFICATE_CHAIN_PASSPHRASE} | \
  aes-wrap ca \
  -config /to_host/tls/root/openssl.cnf.root \
  -extensions v3_intermediate_ca \
  -subj "/CN=Alpine 3-10 Intermediate CA/emailAddress=${ADMIN_CONTACT}/C=${COUNTRY_CODE}/ST=${STATE_NAME}/L=${LOCATION_NAME}/O=${ORGANIZATION_NAME}" \
  -days 365 \
  -notext \
  -batch \
  -passin stdin \
  -in /tls/intermediate/csr/intermediate.csr.pem \
  -out /tls/intermediate/certs/intermediate.cacert.pem
}
tls_concatenate_certificate_bundle () {
  # Vault expects a certificate bundle consisting of a private key in PEM format
  # followed by a certificate in PEM format.
  cat /tls/intermediate/private/intermediate.cakey.pem \
  /tls/intermediate/certs/intermediate.cacert.pem > /tls/intermediate/certs/ca-chain-bundle.cert.pem
}
tls_verify_certificate_bundle () {
  VERIFICATION_RESULT="$( \
    aes-wrap verify \
    -CAfile \
    /to_host/tls/root/certs/cacert.pem \
    /tls/intermediate/certs/ca-chain-bundle.cert.pem \
  )"
}
tls_unset_environment_variables () {
  unset CERTIFICATE_CHAIN_PASSPHRASE
  unset ADMIN_CONTACT
  unset COUNTRY_CODE
  unset STATE_NAME
  unset LOCATION_NAME
  unset ORGANIZATION_NAME
  unset ROOT_CA_CONF_PATH
  unset INTERMEDIATE_CA_CONF_PATH
}