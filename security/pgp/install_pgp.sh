#!/bin/sh

# Name: install_pgp.sh
# Desc: A collection of methods that must be called in proper sequence to install a specific set of data.

check_skip_pgp_install() {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

add_pgp_instructions_to_queue() {
  printf '%s\n' \
  pgp_apk_add_packages \
  pgp_create_home_build_dir \
  pgp_create_home_local_ssl_dir \
  pgp_export_openssl_source_version_wget \
  pgp_change_to_home_build_dir \
  pgp_download_openssl_source_version \
  pgp_extract_openssl_source_version_tar \
  pgp_remove_openssl_source_version_tar \
  pgp_enable_aes_wrapping_in_openssl \
  pgp_change_to_home_build_openssl_version_dir \
  pgp_config_openssl_version_build \
  pgp_make_j_grep_openssl_version_build \
  pgp_make_install_openssl_version_build \
  pgp_create_openssl_shell_script \
  pgp_openssl_v111_in_shrc \
  pgp_verify_openssl_version \
  pgp_create_persist_dir \
  pgp_generate_asc_key_data \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

pgp_apk_add_packages() {
  apk add busybox-static apk-tools-static && \
  apk.static add build-base gnupg linux-headers outils-jot perl 1>&4
  echo -e "\033[7;33mAdded Packages using APK\033[0m" 1>&5
}
pgp_create_home_build_dir() {
  mkdir $HOME/build 1>&4
  echo -e "\033[7;33mCreated ${HOME}/build directory\033[0m" 1>&5
}
pgp_create_home_local_ssl_dir() {
  mkdir -p $HOME/local/ssl 1>&4
  echo -e "\033[7;33mCreated ${HOME}/local/ssl directory\033[0m" 1>&5
}
pgp_export_openssl_source_version_wget() {
  export OPENSSL_SOURCE_VERSION="$(echo \
  $(wget -c https://www.openssl.org/source/index.html -O -) | \
    sed 's/^.*\"\(openssl[-]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[a-zA-Z]\{0,\}\).tar.gz\".*$/\1/g; s/^.* \([^ ]\{1,\}\)$/\1/g;' \
  )" 1>&4
  echo -e "\033[7;33mParsed OpenSSL Version to Variable Using WGET and SED\033[0m" 1>&5
}
pgp_change_to_home_build_dir() {
  cd $HOME/build 1>&4
  echo -e "\033[7;33mChanged Current Directory to ${HOME}/build\033[0m" 1>&5
}
pgp_download_openssl_source_version() {
  wget -c https://openssl.org/source/${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mDownloaded Source TAR for Latest Stable OpenSSL\033[0m" 1>&5
}
pgp_extract_openssl_source_version_tar() {
  tar -xzf ${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mExtracted Source TAR for Latest Stable OpenSSL\033[0m" 1>&5
}
pgp_remove_openssl_source_version_tar() {
  rm -f ${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mForced Removal of Source TAR File\033[0m" 1>&5
}
pgp_enable_aes_wrapping_in_openssl() {
  sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' ./${OPENSSL_SOURCE_VERSION}/apps/enc.c 1>&4
  echo -e "\033[7;33mPatched OpenSSL to Enable AES Wrapping\033[0m" 1>&5
}
pgp_change_to_home_build_openssl_version_dir() {
  cd $HOME/build/${OPENSSL_SOURCE_VERSION} 1>&4
  echo -e "\033[7;33mChanged Current Directory to ${HOME}/build/${OPENSSL_SOURCE_VERSION}\033[0m" 1>&5
}
pgp_config_openssl_version_build() {
  ./config --prefix=$HOME/local --openssldir=$HOME/local/ssl 1>&4
  echo -e "\033[7;33mConfigured Build of OpenSSL\033[0m" 1>&5
}
pgp_make_j_grep_openssl_version_build() {
  make -j$(grep -c ^processor /proc/cpuinfo) 1>&4
  echo -e "\033[7;33mRan Make With -j Option\033[0m" 1>&5
}
pgp_make_install_openssl_version_build() {
  make install_sw 1>&4
  echo -e "\033[7;33mRan Make install_sw to Build OpenSSL (Software Only)\033[0m" 1>&5
}
pgp_make_clean_openssl_version_build() {
  make clean 1>&4
  echo -e "\033[7;33mRan Make clean to Remove Build Files\033[0m" 1>&5
}
pgp_create_openssl_shell_script() {
  echo -e '#!/bin/sh \nenv LD_LIBRARY_PATH=$HOME/local/lib/ $HOME/local/bin/openssl "$@"' > $HOME/local/bin/openssl.sh 1>&4
  chmod 0755 $HOME/local/bin/openssl.sh 1>&4
  echo -e "\033[7;33mExported LD_LIBRARY_PATH Env Var\033[0m" 1>&5
}
pgp_openssl_v111_in_shrc() {
  export OPENSSL_V111="${HOME}/local/bin/openssl.sh"
  # echo -e '#!/bin/sh \nexport OPENSSL_V111="${HOME}/local/bin/openssl.sh"' > $HOME/.shrc 1>&4
  echo -e "\033[7;33mCreated Env Var OPENSSL_V111\033[0m" 1>&5
}
pgp_verify_openssl_version() {
  local OUTPUT_MSG="Verified OpenSSL Version"
  # . $HOME/.shrc
  local VERIFIED="$($OPENSSL_V111 version 2>&1)"
  # local RETURN_ONE=0
  # if [ -z "${VERIFIED}" ] || [ "$(echo "${VERIFIED}" | sed 's/^.*\(not found\)$/\1/g')" == "not found" ]; then
  #   OUTPUT_MSG="ERROR: Unable to Verify OpenSSL Version"
  #   RETURN_ONE=1
  # fi
  # echo -e "\033[7;33m${OUTPUT_MSG}\033[0m" 1>&5
  # [ $RETURN_ONE -eq 1 ] && return 1 # Tell further instructions to abort, the failure of this one is critical.
  echo ""
  echo -n "OPENSSL_V111 printed: ${VERIFIED}"
  echo ""
}
pgp_create_persist_dir() {
  [ ! -d /persist ] && mkdir /persist && echo -e "\033[7;33mDirectory \"/persist\" not found, so created it...\033[0m" 1>&4
  echo -e "\033[7;33mCreated /persist Directory\033[0m" 1>&5
}
pgp_generate_asc_key_data() {
  local MAX_ITER=4
  local ITER=1

  local BATCH_PATH=/tmp/pgpb
  if [ ! -d "${BATCH_PATH}" ]; then
    mkdir -p "${BATCH_PATH}" 1>&4
  fi

  local KEYS_PATH=/pgp/keys
  if [ ! -d "${KEYS_PATH}" ]; then
    mkdir -p "${KEYS_PATH}" 1>&4
  fi

  local PHRASES_PATH=/pgp/phrases
  if [ ! -d "${PHRASES_PATH}" ]; then
    mkdir "${PHRASES_PATH}" 1>&4
  fi

  local PGP_WRAP_PAD_PAYLOAD=
  local PGP_WRAP_PAD_EPHEMERAL=
  local PGP_WRAP_PAD_PRIVATE=
  local PGP_WRAP_PAD_PUBLIC=

  while [ $ITER -le $MAX_ITER ]; do
    local BATCH_FILE=${BATCH_PATH}/.$(tr -cd a-f0-9 < /dev/urandom | fold -w32 | head -n1)
    local PHRASE_LEN=$(jot -w %i -r 1 20 99)
    local PHRASE=$(tr -cd [[:alnum:][:punct:]] < /dev/urandom | fold -w${PHRASE_LEN} | head -n1)
    local ITER_STR=$(printf '%0'"${#MAX_ITER}"'d' ${ITER})
    local DONE_MSG=
    [ $ITER -eq $MAX_ITER ] && DONE_MSG="%echo Done!" || DONE_MSG="%echo Key Details Complete."
    
    # Declare encryption variables
    PGP_WRAP_PAD_PAYLOAD="$($OPENSSL_V111 rand 32)"
    PGP_WRAP_PAD_EPHEMERAL="$($OPENSSL_V111 rand 32)"
    PGP_WRAP_PAD_PRIVATE="$( \
      $OPENSSL_V111 genpkey \
      -outform PEM \
      -algorithm RSA \
      -pkeyopt rsa_keygen_bits:4096 | \
      base64 | tr -d '\n' | sed s'/ //g' \
    )"
    PGP_WRAP_PAD_PUBLIC="$( \
      echo ${PGP_WRAP_PAD_PRIVATE} | base64 -d | \
      $OPENSSL_V111 rsa \
      -inform PEM \
      -outform PEM \
      -pubout | \
      base64 | tr -d '\n' | sed 's/ //g' \
    )"

    # Persist each phrase as an encrypted external file.
    echo "key_${ITER_STR}_asc::${PHRASE}" | \
    $OPENSSL_V111 enc -id-aes256-wrap-pad \
    -K $(echo "${PGP_PAYLOAD}" | hexdump -v -e '/1 "%02X"') \
    -iv A65959A6 \
    -out /persist/pgp_key_${ITER_STR}.asc.wrapped 2>/dev/null 1>&4

    # Wrap the payload in the ephemeral.
    local PGP_WRAP_PAD_PAYLOAD_WRAPPED="$( \
      echo "${PGP_WRAP_PAD_PAYLOAD}" | \
      $OPENSSL_V111 enc -id-aes256-wrap-pad \
      -K $(echo "${PGP_WRAP_PAD_EPHEMERAL}" | hexdump -v -e '/1 "%02X"') \
      -iv A65959A6 | \
      base64 | tr -d '\n' | sed 's/ //g' \
    )"
    
    # Wrap the ephemeral in the public key.
    mkfifo pgp_public_named_pipe
    ( echo "${TLS_WRAP_PAD_PUBLIC}" > pgp_public_named_pipe & )
    #
    local PGP_WRAP_PAD_EPHEMERAL_WRAPPED="$( \
      echo "${PGP_WRAP_PAD_EPHEMERAL}" | \
      $OPENSSL_V111 pkeyutl \
      -encrypt \
      -pubin -inkey pgp_public_named_pipe \
      -pkeyopt rsa_padding_mode:oaep \
      -pkeyopt rsa_oaep_md:sha1 \
      -pkeyopt rsa_mgf1_md:sha1 | \
      base64 | tr -d '\n' | sed 's/ //g' \
    )"
    #
    ( rm -f pgp_public_named_pipe )

    # Concatenate the ephemeral wrapped and payload wrapped into rsa aes wrapped.
    echo "${PGP_WRAP_PAD_EPHEMERAL_WRAPPED}" >> /persist/pgp-key-${ITER_STR}.rsa-aes.wrapped 1>&4
    echo "${PGP_WRAP_PAD_PAYLOAD_WRAPPED}" >> /persist/pgp-key-${ITER_STR}.rsa-aes.wrapped 1>&4

    # Export the private key to /persist.
    printf '%s\n' ${PGP_WRAP_PAD_PRIVATE} > /persist/pgp-key-${ITER_STR}.private.key 1>&4

    printf '%s\n' \
      "%echo Generating Key [ $ITER / $MAX_ITER ]" \
      "Key-Type: RSA" \
      "Key-Length: 4096" \
      "Subkey-Type: RSA" \
      "Subkey-Length: 4096" \
      "Passphrase: ${PHRASE}" \
      "Name-Real: ${name_real:-Thomas Tester}" \
      "Name-Email: ${name_email:-test@thesupertask.com}" \
      "Name-Comment: ${name_comment:-Auto-generated Key Used for Testing.}" \
      "Expire-Date: 0" \
      "%commit" \
    "${DONE_MSG}" >> $BATCH_FILE
    gpg \
      --verbose \
      --batch \
    --gen-key $BATCH_FILE 1>&4
    sleep 1s # .............. SLEEP
    rm -f $BATCH_FILE 1>&4

    local REVOC_FILE="$(ls -t ${HOME}/.gnupg/openpgp-revocs.d | head -n1)"
    gpg \
      --export \
      "$(basename ${REVOC_FILE} | cut -f1 -d '.')" | \
    base64 > "${KEYS_PATH}/key_${ITER_STR}.asc"
    ITER=$(($ITER + 1))
  done
  echo -e "\033[7;33mGenerated PGP Data\033[0m" 1>&5
}