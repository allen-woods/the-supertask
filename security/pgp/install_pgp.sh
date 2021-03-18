#!/bin/sh

# Name: install_pgp.sh
# Desc: A collection of methods that must be called in proper sequence to install a specific set of data.

check_skip_pgp_install() {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

add_pgp_instructions_to_queue() {
  printf '%s\n' \
  pgp_create_to_host_dir \
  pgp_generate_asc_key_data \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

pgp_create_to_host_dir() {
  [ ! -d /to_host/pgp ] && mkdir /to_host/pgp && echo -e "\033[7;33mDirectory \"/to_host/pgp\" not found, so created it...\033[0m" 1>&4
  echo -e "\033[7;33mCreated /to_host/pgp Directory\033[0m" 1>&5
}
pgp_generate_asc_key_data() {
  OPENSSL_V111=$HOME/local/bin/openssl.sh
  echo "OPENSSL_V111 inside of pgp resolves to: ${OPENSSL_V111}"
  echo "Version command: $($OPENSSL_V111 version)"

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

  local PHRASES_PATH=/to_host/pgp/phrases
  if [ ! -d "${PHRASES_PATH}" ]; then
    mkdir "${PHRASES_PATH}" 1>&4
  fi

  local ENC_PATH=/to_host/pgp/enc
  if [ ! -d "${ENC_PATH}" ]; then
    # We create directories in the manner below because
    # currently, mkdir option -p appears to fail when 
    # creating paths on the host system.

    mkdir /to_host/pgp 1>&4
    mkdir /to_host/pgp/enc 1>&4
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
      -K $(echo "${PGP_WRAP_PAD_PAYLOAD}" | hexdump -v -e '/1 "%02X"') \
      -iv A65959A6 \
      -out ${PHRASES_PATH}/pgp_key_${ITER_STR}.asc.wrapped

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
    echo "${PGP_WRAP_PAD_EPHEMERAL_WRAPPED}" >> ${ENC_PATH}/pgp-key-${ITER_STR}.rsa-aes.wrapped
    echo "${PGP_WRAP_PAD_PAYLOAD_WRAPPED}" >> ${ENC_PATH}/pgp-key-${ITER_STR}.rsa-aes.wrapped

    # Export the private key to /to_host/pgp.
    printf '%s\n' ${PGP_WRAP_PAD_PRIVATE} > /to_host/pgp/pgp-key-${ITER_STR}.private.key

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
    --gen-key $BATCH_FILE
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