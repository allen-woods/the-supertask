#!/bin/sh

# PGP script for macOS 10.14.6+ running under gnupg 2.2.27 and libgcrypt 1.9.2

call_instructions() {
  pgp_export_lc_ctype && \
  pgp_create_batch_dir && \
  pgp_create_pgp_keys_dir && \
  pgp_create_pgp_phrases_dir && \
  pgp_generate_asc_key_data && \
}
pgp_export_lc_ctype() {
  export LC_CTYPE=C
}
pgp_create_batch_dir() {
  [ ! -d /private/tmp/pgpb ] && mkdir -pm 0700 /private/tmp/pgpb && \
  export BATCH_PATH=/private/tmp/pgpb
}
pgp_create_pgp_keys_dir() {
  [ ! -d ${CONTAINER_PATH}/pgp/keys ] && mkdir -pm 0700 ${CONTAINER_PATH}/pgp/keys && \
  export KEYS_PATH=${CONTAINER_PATH}/pgp/keys
}
pgp_create_pgp_phrases_dir() {
  [ ! -d ${CONTAINER_PATH}/pgp/phrases ] && mkdir -m 0700 ${CONTAINER_PATH}/pgp/phrases && \
  export PHRASES_PATH=${CONTAINER_PATH}/pgp/phrases
}
pgp_generate_asc_key_data() {
  if [ -z "$(ls -A ${KEYS_PATH})" ] && [ -z "$(ls -A ${PHRASES_PATH})" ]; then
    local max_iter=4
    local iter=1
    while [ $iter -le $max_iter ]; do
      local batch_file=${BATCH_PATH}/.$(tr -cd a-f0-9 < /dev/urandom | fold -w16 | head -n1)
      local phrase_len=$(jot -w %i -r 1 20 99)
      local phrase=$(tr -cd '[:graph:]' < /dev/urandom | fold -w${phrase_len} | head -n1)
      local iter_str=$(printf '%0'"${#max_iter}"'d' ${iter})
      local done_msg=
      [ $iter -eq $max_iter ] && done_msg="%echo Done!" || done_msg="%echo Key Details Complete."
      printf '%s\n' \
        "%echo Generating Key [ $iter / $max_iter ]" \
        "Key-Type: RSA" \
        "Key-Length: 4096" \
        "Subkey-Type: RSA" \
        "Subkey-Length: 4096" \
        "Passphrase: ${phrase}" \
        "Name-Real: ${name_real:-Thomas Tester}" \
        "Name-Email: ${name_email:-test@thesupertask.com}" \
        "Name-Comment: ${name_comment:-Auto-generated Key Used for Testing.}" \
        "Expire-Date: 0" \
        "%commit" \
      "${done_msg}" >> $batch_file
      echo "key_${iter_str}.asc::${phrase}" | base64 >> ${PHRASES_PATH}/.phrases
      gpg \
        --verbose \
        --batch \
      --gen-key $batch_file
      #
      sleep 1s # .............. SLEEP
      #
      rm -f $batch_file
      local revoc_file="$(ls -t ${HOME}/.gnupg/openpgp-revocs.d | head -n1)"
      gpg \
        --export \
        "$(basename ${revoc_file} | cut -f1 -d '.')" | \
      base64 > "${KEYS_PATH}/key_${iter_str}.asc"
      iter=$(($iter + 1))
    done
    echo -e "\033[7;33mGenerated PGP Data\033[0m"
  fi
}

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

# call_instructions() {
#   pgp_create_home_build_dir && \
#   pgp_create_home_local_ssl_dir && \
#   pgp_export_openssl_source_version_wget && \
#   pgp_openssl_source_version_grep_version_str && \
#   pgp_openssl_source_version_grep_version_num && \
#   pgp_openssl_source_version_head_first_result && \
#   pgp_openssl_source_version_sed_remove_tar && \
#   pgp_change_to_home_build_dir && \
#   pgp_download_openssl_source_version && \
#   pgp_extract_openssl_source_version_tar && \
#   pgp_remove_openssl_source_version_tar && \
#   pgp_enable_aes_wrapping_in_openssl && \
#   pgp_change_to_home_build_openssl_version_dir && \
#   pgp_config_openssl_version_build && \
#   pgp_make_j_grep_openssl_version_build && \
#   pgp_make_install_openssl_version_build && \
#   pgp_export_ld_library_path && \
#   pgp_export_openssl_v111 && \
#   pgp_verify_openssl_version
# }

# create_home_build_dir() {
#   mkdir $HOME/build
#   echo -e "\033[7;33mCreated ${HOME}/build directory\033[0m"
# }
# create_home_local_ssl_dir() {
#   mkdir -p $HOME/local/ssl
#   echo -e "\033[7;33mCreated ${HOME}/local/ssl directory\033[0m"
# }
# export_openssl_source_version_wget() {
#   export OPENSSL_SOURCE_VERSION="$(wget -c https://www.openssl.org/source/index.html -O -)"
#   echo -e "\033[7;33mSaved OpenSSL.org HTML File to Variable Using WGET\033[0m"
# }
# openssl_source_version_grep_version_str() {
#   OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | grep -o '\"openssl-.*.tar.gz\"')"
#   echo -e "\033[7;33mParsed OpenSSL Version Strings from HTML Syntax\033[0m"
# }
# openssl_source_version_grep_version_num() {
#   OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | grep -o '[0-9]\{1\}.[0-9]\{1\}.[0-9]\{1\}[a-z]\{0,\}.tar')"
#   echo -e "\033[7;33mParsed OpenSSL Version Release Numbers from Strings\033[0m"
# }
# openssl_source_version_head_first_result() {
#   OPENSSL_SOURCE_VERSION="$(printf '%s\n' "${OPENSSL_SOURCE_VERSION}" | head -n1)"
#   echo -e "\033[7;33mParsed Latest Stable Version of OpenSSL from Release Numbers\033[0m"
# }
# openssl_source_version_sed_remove_tar() {
#   OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | sed 's/.tar$//g')"
#   echo -e "\033[7;33mRemoved Unwanted Trailing Data from Latest Stable\033[0m"
# }
# change_to_home_build_dir() {
#   cd $HOME/build
#   echo -e "\033[7;33mChanged Current Directory to ${HOME}/build\033[0m"
# }
# download_openssl_source_version() {
#   wget -c https://openssl.org/source/openssl-${OPENSSL_SOURCE_VERSION}.tar.gz
#   echo -e "\033[7;33mDownloaded Source TAR for Latest Stable OpenSSL\033[0m"
# }
# extract_openssl_source_version_tar() {
#   tar -xzf openssl-${OPENSSL_SOURCE_VERSION}.tar.gz
#   echo -e "\033[7;33mExtracted Source TAR for Latest Stable OpenSSL\033[0m"
# }
# remove_openssl_source_version_tar() {
#   rm -f openssl-${OPENSSL_SOURCE_VERSION}.tar.gz
#   echo -e "\033[7;33mForced Removal of Source TAR File\033[0m"
# }
# enable_aes_wrapping_in_openssl() {
#   sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' ./openssl-${OPENSSL_SOURCE_VERSION}/apps/enc.c
#   echo -e "\033[7;33mPatched OpenSSL to Enable AES Wrapping\033[0m"
# }
# change_to_home_build_openssl_version_dir() {
#   cd $HOME/build/openssl-${OPENSSL_SOURCE_VERSION}
#   echo -e "\033[7;33mChanged Current Directory to ${HOME}/build/openssl-${OPENSSL_SOURCE_VERSION}\033[0m"
# }
# config_openssl_version_build() {
#   ./config --prefix=$HOME/local --openssldir=$HOME/local/ssl
#   echo -e "\033[7;33mConfigured Build of OpenSSL\033[0m"
# }
# make_j_grep_openssl_version_build() {
#   make -j$(grep -c ^processor /proc/cpuinfo)
#   echo -e "\033[7;33mRan Make With -j Option\033[0m"
# }
# make_install_openssl_version_build() {
#   make install
#   echo -e "\033[7;33mRan Make Install to Build OpenSSL\033[0m"
# }
# export_ld_library_path() {
#   export LD_LIBRARY_PATH=$HOME/local/lib/
#   echo -e "\033[7;33mExported LD_LIBRARY_PATH Env Var\033[0m"
# }
# export_openssl_v111() {
#   export OPENSSL_V111=$HOME/local/bin/openssl
#   echo -e "\033[7;33mExported OPENSSL_V111 Env Var\033[0m"
# }
# verify_openssl_version() {
#   $OPENSSL_V111 version
#   echo -e "\033[7;33mVerified OpenSSL Version\033[0m"
# }
#
# pgp_generate_asc_key_data() {
#   # ......................... Default number of iterations is 4.
#   local max_iter=4
#   # ......................... Begin on iteration 1.
#   local iter=1
#   # ......................... Where the batch file should be stored.
#   local batch_dir=/tmp/pgpb
#   # ......................... If the dir doesn't exist,
#   if [ ! -d "${batch_dir}" ]; then
#     # ....................... Make it.
#     mkdir -p "${batch_dir}"
#   fi
#   # ......................... Where the key files should be stored.
#   local key_dest_dir=/pgp/keys
#   # ......................... If the dir doesn't exist,
#   if [ ! -d "${key_dest_dir}" ]; then
#     # ....................... Make it.
#     mkdir -p "${key_dest_dir}"
#   fi
#   # ......................... Reserve a pipe to store our data in.
#   pipe_crud -c -P=pgp_data -D=pgp_keys --secure
#   # ......................... Iterate from 1 to N.
#   while [ $iter -le $max_iter ]; do
#     # ....................... Generate unique, random batch file.
#     local batch_file=${batch_dir}/.$(tr -cd a-f0-9 < /dev/urandom | fold -w16 | head -n1)
#     # ....................... Generate random phrase length.
#     local phrase_len=$(jot -w %i -r 1 20 99)
#     # ....................... Generate random phrase.
#     local phrase=$(tr -cd [[:alnum:][:punct:]] < /dev/urandom | fold -w${phrase_len} | head -n1)
#     # ....................... Format the key number based on length and value of N.
#     local iter_str=$(printf '%0'"${#max_iter}"'d' ${iter})
#     # ....................... Delare a message to display when each key is done.
#     local done_msg=
#     # ....................... conditionally assign a value to the done message.
#     [ $iter -eq $max_iter ] && done_msg="%echo Done!" || done_msg="%echo Key Details Complete."
#     # ....................... Print the contents of eah batch.
#     printf '%s\n' \
#       "%echo Generating Key [ $iter / $max_iter ]" \
#       "Key-Type: RSA" \
#       "Key-Length: 4096" \
#       "Subkey-Type: RSA" \
#       "Subkey-Length: 4096" \
#       "Passphrase: ${phrase}" \
#       "Name-Real: ${name_real:-Thomas Tester}" \
#       "Name-Email: ${name_email:-test@thesupertask.com}" \
#       "Name-Comment: ${name_comment:-Auto-generated Key Used for Testing.}" \
#       "Expire-Date: 0" \
#       "%commit" \
#     "${done_msg}" >> $batch_file
#     # ....................... Put sensitive data into the pipe first.
#     pipe_crud -u -P=pgp_data -D=pgp_keys -I={\"key_${iter_str}_asc\":\"$(echo "${phrase}" | base64 | tr -d '\n' | sed 's/ //g')\"} 2>/dev/null
#     # ....................... Generate the Nth key.
#     gpg2 \
#       --verbose \
#       --batch \
#     --gen-key $batch_file
#     #
#     sleep 1s # .............. SLEEP
#     #
#     # ....................... Delete the batch file.
#     rm -f $batch_file
#     # ....................... Identify the newest key made.
#     local revoc_file="$(ls -t ${HOME}/.gnupg/openpgp-revocs.d | head -n1)"
#     # ....................... Export the newest key.
#     gpg2 \
#       --export \
#       "$(basename ${revoc_file} | cut -f1 -d '.')" | \
#     base64 > "${key_dest_dir}/key_${iter_str}.asc"
#     # ....................... Increment plus one.
#     iter=$(($iter + 1))
#   done
#   # ......................... Give the user feedback.
#   echo -e "\033[7;33mGenerated PGP Data\033[0m"
# }
# pgp_generate_payload_aes() {
#   local PAYLOAD="$( \
#     $OPENSSL_V111 rand 32 | \
#     base64 | tr -d '\n' | sed 's/ //g' \
#   )"
#   pipe_crud -c -P=pgp_data -D=payload -I={\"aes\":\"${PAYLOAD}\"}
#   echo "payload: $(pipe_crud -r -P=pgp_data -D=payload -I={\"aes\"} | base64 -d)"
#   echo "original: $(echo ${PAYLOAD} | base64 -d)"
#   echo -e "\033[7;33mGenerated Random Payload\033[0m"
# }
# generate_ephemeral_aes() {
#   local EPHEMERAL="$( \
#     $OPENSSL_V111 rand 32 | \
#     base64 | tr -d '\n' | sed 's/ //g' \
#   )"
#   pipe_crud -c -P=pgp_data -D=ephemeral -I={\"aes\":\"${EPHEMERAL}\"}
#   echo "ephemeral: $(pipe_crud -r -P=pgp_data -D=ephemeral -I={\"aes\"} | base64 -d)"
#   echo "original: $(echo ${EPHEMERAL} | base64 -d)"
#   echo -e "\033[7;33mGenerated Random Ephemeral\033[0m"
# }
# generate_private_rsa() {
#   local PRIVATE_KEY="$( \
#     $OPENSSL_V111 genpkey \
#     -outform PEM \
#     -algorithm RSA \
#     -pkeyopt rsa_keygen_bits:4096 | \
#     base64 | tr -d '\n' | sed 's/ //g' \
#   )"
#   pipe_crud -c -P=pgp_data -D=private_rsa -I={\"key\":\"${PRIVATE_KEY}\"}
#   echo "private rsa: $(pipe_crud -r -P=pgp_data -D=private_rsa -I={\"key\"} | base64 -d)"
#   echo -e "\033[7;33mGenerated Private Key\033[0m"
# }
# generate_public_rsa() {
#   local PRIVATE_KEY="$( \
#     pipe_crud -r -P=pgp_data -D=private_rsa -I={\"key\"} | \
#     base64 -d \
#   )"
#   local PUB_KEY="$( \
#     echo "${PRIVATE_KEY}" | \
#     $OPENSSL_V111 rsa -inform PEM -outform PEM -pubout | \
#     base64 | tr -d '\n' | sed 's/ //g' \
#   )"
#   pipe_crud -c -P=pgp_data -D=public_rsa -I={\"key\":\"${PUB_KEY}\"}
#   echo "public rsa: $(pipe_crud -r -P=pgp_data -D=public_rsa -I={\"key\"} | base64 -d)"
#   echo -e "\033[7;33mGenerated Public Key\033[0m"
# }
# enc_phrases_with_payload() {
#   local PAYLOAD_HEX="$( \
#     pipe_crud -r -P=pgp_data -D=payload -I={\"aes\"} | \
#     base64 -d | \
#     hexdump -v -e '/1 "%02X"' \
#   )"
#   local PGP_KEYS="$( \
#     pipe_crud -r -P=pgp_data -D=pgp_keys \
#   )"
#   echo "${PGP_KEYS}" | $OPENSSL_V111 enc -id-aes256-wrap-pad -K ${PAYLOAD_HEX} -iv A65959A6 -out /pgp/keys/phrases_wrapped
#   echo -e "\033[7;33mEncrypted PGP Key Pass Phrases with Payload AES\033[0m"
# }
# wrap_payload_in_ephemeral() {
#   local PAYLOAD_AES="$( \
#     pipe_crud -r -P=pgp_data -D=payload -I={\"aes\"} | \
#     base64 -d \
#   )"
#   local EPHEMERAL_HEX="$( \
#     pipe_crud -r -P=pgp_data -D=ephemeral -I={\"aes\"} | \
#     base64 -d | \
#     hexdump -v -e '/1 "%02X"' \
#   )"
#   local PAYLOAD_WRAPPED="$( \
#     echo "${PAYLOAD_AES}" | \
#     $OPENSSL_V111 enc -id-aes256-wrap-pad \
#     -K "${EPHEMERAL_HEX}" \
#     -iv A65959A6 | \
#     base64 | tr -d '\n' | sed 's/ //g' \
#   )"
#   pipe_crud -c -P=pgp_data -D=payload_wrapped -I={\"enc\":\"${PAYLOAD_WRAPPED}\"}
#   echo "payload_wrapped: $(pipe_crud -r -P=pgp_data -D=payload_wrapped -I={\"enc\"} | base64 -d)"
#   echo -e "\033[7;33mWrapped Payload AES with Ephemeral AES\033[0m"
# }
# wrap_ephemeral_in_public_key() {
#   local EPHEMERAL_AES="$( \
#     pipe_crud -r -P=pgp_data -D=ephemeral -I={\"aes\"} | \
#     base64 -d \
#   )"
#   local PUB_KEY="$( \
#     pipe_crud -r -P=pgp_data -D=public_rsa -I={\"key\"} | \
#     base64 -d \
#   )"
#   mkfifo public_pem
#   ( echo "${PUB_KEY}" > public_pem & )
#   local EPHEMERAL_WRAPPED="$( \
#     echo "${EPHEMERAL_AES}" | \
#     $OPENSSL_V111 pkeyutl \
#     -encrypt \
#     -pubin -inkey public_pem \
#     -pkeyopt rsa_padding_mode:oaep \
#     -pkeyopt rsa_oaep_md:sha1 \
#     -pkeyopt rsa_mgf1_md:sha1 | \
#     base64 | tr -d '\n' | sed 's/ //g' \
#   )"
#   ( rm -f public_pem )
#   pipe_crud -c -P=pgp_data -D=ephemeral_wrapped -I={\"enc\":\"${EPHEMERAL_WRAPPED}\"}
#   echo "ephemeral_wrapped: $(pipe_crud -r -P=pgp_data -D=ephemeral_wrapped -I={\"enc\"} | base64 -d)"
#   echo -e "\033[7;33mWrapped Ephemeral AES with Public Key\033[0m"
# }
# persist_rsa_aes_wrapped() {
#   local EPHEMERAL_WRAPPED="$( \
#     pipe_crud -r -P=pgp_data -D=ephemeral_wrapped -I={\"enc\"} | \
#     base64 -d \
#   )"
#   local PAYLOAD_WRAPPED="$( \
#     pipe_crud -r -P=pgp_data -D=payload_wrapped -I={\"enc\"} | \
#     base64 -d \
#   )"
#   echo ${EPHEMERAL_WRAPPED} >> /pgp/rsa_aes_wrapped
#   echo ${PAYLOAD_WRAPPED} >> /pgp/rsa_aes_wrapped
#   cat /pgp/rsa_aes_wrapped
#   echo -e "\033[7;33mPrinted RSA AES Wrapped Data to File\033[0m"
# }