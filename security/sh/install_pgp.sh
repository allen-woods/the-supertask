#!/bin/sh

# Name: install_pgp.sh
# Desc: A thorough collection of shell script functions and commands
#       that are necessary for initializing a PGP-hardened instance
#       of HashiCorp Vault on Alpine Linux (3.10.5+).
#
# NOTE: While these scripts and commands have been authored to be
#       portable wherever possible, this effort is based on current
#       knowledge of POSIX conformance in `/bin/sh`.
#       As such, these scripts can still be improved and should not
#       be considered fully optimized for a given purpose.

check_skip_pgp_install() {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

add_pgp_instructions_to_queue() {
  printf '%s\n' \
  pgp_apk_add_packages \
  pgp_create_home_directories \
  pgp_start_gpg_agent_as_daemon \
  pgp_insure_vault_addr_exported \
  pgp_run_vault_server_as_background_process \
  pgp_generate_asc_key_data \
  pgp_pkill_gpg_agent_daemon \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

pgp_apk_add_packages() {
  apk add \
    busybox-static \
    apk-tools-static && \
  apk.static add \
    curl \
    gnupg \
    outils-jot \
    pinentry-gtk \
    vim
}
pgp_create_home_directories() {
  local HOME_WRAPPED_PATH=$HOME/.wrapped
  local HOME_UNSEAL_PATH=$HOME/.unseal
  local HOME_RAW_PATH=$HOME/.raw
  [ ! -d "${HOME_WRAPPED_PATH}" ] && mkdir -pm 0700 "${HOME_WRAPPED_PATH}"
  [ ! -d "${HOME_UNSEAL_PATH}" ] && mkdir -pm 0700 "${HOME_UNSEAL_PATH}"
  [ ! -d "${HOME_RAW_PATH}" ] && mkdir -pm 0700 "${HOME_RAW_PATH}"
}
pgp_start_gpg_agent_as_daemon() {
  gpg-agent --daemon --pinentry-program pinentry-gtk
}
pgp_insure_vault_addr_exported() {
  [ -z "${VAULT_ADDR}" ] && export VAULT_ADDR="http://127.0.0.1:8200"
}
pgp_run_vault_server_as_background_process() {
  ( \
    /usr/bin/dumb-init /bin/sh /usr/local/bin/docker-entrypoint.sh server & \
  ) >/dev/null 2>&1
}
pgp_generate_asc_key_data() {
  # The starting iteration to generate is always 1.
  local ITER=${ITER:-1}
  # Default max number of keys to generate is 4.
  local MAX_ITER=${MAX_ITER:-4}
  # NOTE: In order to adjust MAX_ITER, you must hard-code it. Use of $1 argument always results in the incoming value of `2`.

  # These are paths to PGP keys required by the `vault operator init` CLI command.
  local ROOT_TOKEN_PGP_KEY_ASC_FILE=
  local PGP_KEYS_COMMA_DELIMITED_ASC_FILES=
  
  # This value is used inside the loop(s) below to assign path strings to the above file paths.
  local n=0

  # export OPENSSL_V111=$HOME/local/bin/openssl.sh # OpenSSL Might Not Be Needed.

  # Create a directory dedicated to the raw files.
  local PGP_SRC_PATH=$HOME/pgp_raw_files
  mkdir -pm 0700 $PGP_SRC_PATH
  
  # Create a directory dedicated to the encrypted (wrapped) files.
  local PGP_DST_PATH=$HOME/pgp_enc_files
  mkdir -pm 0700 $PGP_DST_PATH


  # Iterate through the PGP keys in the batch.
  while [ $ITER -le $MAX_ITER ]; do
    local BATCH_FILE=${BATCH_PATH}/.$(tr -cd a-f0-9 < /dev/random | fold -w32 | head -n1)
    local PHRASE_LEN=$(jot -w %i -r 1 20 99)
    local PHRASE=$(tr -cd [[:alnum:][:punct:]] < /dev/random | fold -w${PHRASE_LEN} | head -n1)
    local ITER_STR=$(printf '%0'"${#MAX_ITER}"'d' ${ITER})
    local DONE_MSG=${DONE_MSG:-"%echo Key Details Complete."}
    [ $ITER -eq $MAX_ITER ] && DONE_MSG="%echo Done!"

    # # Generate the payload AES file.
    # $OPENSSL_V111 rand -out ${PGP_SRC_PATH}/payload-aes-${ITER_STR}.bin 32
    # # Store hex string of payload.
    # local PAYLOAD_HEX=$(hexdump -v -e '/1 "%02X"' < ${PGP_SRC_PATH}/payload-aes-${ITER_STR}.bin)
    
    # # Generate the ephemeral AES file.
    # $OPENSSL_V111 rand -out ${PGP_SRC_PATH}/ephemeral-aes-${ITER_STR}.bin 32
    # # Store hex string of ephemeral.
    # local EPHEMERAL_HEX=$(hexdump -v -e '/1 "%02X"' < ${PGP_SRC_PATH}/ephemeral-aes-${ITER_STR}.bin)

    # # * * * * *

    # # NOTE:
    # #       Commented code below is provided here for completeness only.
    # #       The use of passphrases with RSA keypairs involved in key wrap
    # #       algorithms presents an additional layer of complexity for
    # #       encrypting data-at-rest.
    # #
    # #       We omit these passphrases here to reduce that complexity on
    # #       purpose.

    # # Uncomment code block below for passphrase support.
    # # # Generate length of passphrase for private key.
    # # local PRIVATE_KEY_PHRASE_LEN=$(jot -w %i -r 1 32 64)
    # # # Generate passphrase for private key.
    # # local PRIVATE_KEY_PASS_PHRASE=$(tr -cd [[:alnum:][:punct:]] < /dev/random | fold -w${PRIVATE_KEY_PHRASE_LEN} | head -n1)
    # # # Persist passphrase to file.
    # # echo "${PRIVATE_KEY_PASS_PHRASE}" > ${PGP_SRC_PATH}/private-key-${ITER_STR}-passphrase

    # # Generate private key.
    # $OPENSSL_V111 genpkey \
    # -out ${PGP_DST_PATH}/id-aes256-wrap-pad-private-key-${ITER_STR}.pem \
    # -outform PEM \
    # -algorithm RSA \
    # -pkeyopt rsa_keygen_bits:4096
    # # Place next line below "-algorithm RSA" above and uncomment for passphrase support.
    # # -pass file:${PGP_SRC_PATH}/private-key-${ITER_STR}-passphrase \

    # # * * * * *

    # # Uncomment code block below for passphrase support.
    # # # Generate length of passphrase for public key.
    # # local PUBLIC_KEY_PHRASE_LEN=$(jot -w %i -r 1 32 64)
    # # # Generate passphrase for public key.
    # # local PUBLIC_KEY_PASS_PHRASE=$(tr -cd [[:alnum:][:punct:]] < /dev/random | fold -w${PUBLIC_KEY_PHRASE_LEN} | head -n1)
    # # # Persist passphrase to file.
    # # echo "${PUBLIC_KEY_PASS_PHRASE}" > ${PGP_SRC_PATH}/public-key-${ITER_STR}-passphrase

    # # Generate public key.
    # $OPENSSL_V111 rsa \
    # -inform PEM \
    # -in ${PGP_DST_PATH}/id-aes256-wrap-pad-private-key-${ITER_STR}.pem \
    # -outform PEM \
    # -pubout \
    # -out ${PGP_DST_PATH}/id-aes256-wrap-pad-public-key-${ITER_STR}.pem
    # # Place next line below "-pubout \" above and uncomment for passphrase support.
    # # -passout file:${PGP_SRC_PATH}/public-key-${ITER_STR}-passphrase \

    # # * * * * *

    # Persist passphrase of PGP key to file.
    echo "${PHRASE}" > $HOME/.raw/pgp-key-${ITER_STR}-asc-passphrase.raw

    # # Encrypt the PGP key's passphrase file using the payload.
    # $OPENSSL_V111 enc \
    # -id-aes256-wrap-pad \
    # -K $PAYLOAD_HEX \
    # -iv A65959A6 \
    # -in ${PGP_SRC_PATH}/pgp-key-${ITER_STR}-asc-passphrase.raw \
    # -out ${PGP_DST_PATH}/pgp-key-${ITER_STR}-asc-passphrase.wrapped

    # # * * * * *

    # # Wrap the payload in the ephemeral.
    # $OPENSSL_V111 enc \
    # -id-aes256-wrap-pad \
    # -K $EPHEMERAL_HEX \
    # -iv A65959A6 \
    # -in ${PGP_SRC_PATH}/payload-aes-${ITER_STR}.bin \
    # -out ${PGP_DST_PATH}/payload-aes-${ITER_STR}.wrapped \

    # # Wrap the ephemeral in the public key.
    # $OPENSSL_V111 pkeyutl \
    # -encrypt \
    # -in ${PGP_SRC_PATH}/ephemeral-aes-${ITER_STR}.bin \
    # -out ${PGP_DST_PATH}/ephemeral-aes-${ITER_STR}.wrapped \
    # -pubin \
    # -inkey ${PGP_DST_PATH}/id-aes256-wrap-pad-public-key-${ITER_STR}.pem \
    # -pkeyopt rsa_padding_mode:oaep \
    # -pkeyopt rsa_oaep_md:sha1 \
    # -pkeyopt rsa_mgf1_md:sha1
    # # Place next line below "-pubin \" above and uncomment for passphrase support.
    # # -passin file:${PGP_SRC_PATH}/public-key-${ITER_STR}-passphrase \

    # # * * * * *

    # # Concatenate the wrapped ephemeral and payload into one main file.
    # cat \
    # ${PGP_DST_PATH}/ephemeral-aes-${ITER_STR}.wrapped \
    # ${PGP_DST_PATH}/payload-aes-${ITER_STR}.wrapped > ${PGP_DST_PATH}/rsa-aes-wrapped-${ITER_STR}.bin
    # # This *.bin file can be safely distributed, but be careful with the
    # # corresponding private key!

    # Generate the batch for this specific PGP key.
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
    "${DONE_MSG}" > $BATCH_FILE

    # Generate the PGP key by running the batch file.
    gpg \
    --pinentry-mode loopback \
    --verbose \
    --batch \
    --gen-key $BATCH_FILE

    # Delete the batch file after use.
    rm -f $BATCH_FILE

    # Capture the most recently generated revocation file.
    # We need to parse its hexadecimal filename to export the key as an ASC file.
    local MOST_RECENT_REVOC_CERT=$( ls -t ${HOME}/.gnupg/openpgp-revocs.d | head -n1 )
    local PGP_GENERATED_KEY_ID_HEX=$( basename ${MOST_RECENT_REVOC_CERT} | cut -f1 -d '.' )
    local PGP_EXPORTED_ASC_KEY_FILE="${PGP_DST_PATH}/key_${ITER_STR}.asc"

    # Export the key in base64 encoded *.asc format (what Vault consumes).
    gpg \
    --export \
    ${PGP_GENERATED_KEY_ID_HEX} | \
    base64 > ${PGP_EXPORTED_ASC_KEY_FILE}

    # Increment the value of `n`.
    # IMPORTANT:  We must increment in advance to prevent overrun of
    #             generated key quantity during call of
    #             `vault operator init` below.
    n=$(($n + 1))

    if [ $n -eq 1 ]; then
      [ -z "${ROOT_TOKEN_PGP_KEY_ASC_FILE}" ] && ROOT_TOKEN_PGP_KEY_ASC_FILE="${PGP_EXPORTED_ASC_KEY_FILE}"
    elif [ $n -gt 1 ]; then
      [ -z "${PGP_KEYS_COMMA_DELIMITED_ASC_FILES}" ] && \
      PGP_KEYS_COMMA_DELIMITED_ASC_FILES="${PGP_EXPORTED_ASC_KEY_FILE}" || \
      PGP_KEYS_COMMA_DELIMITED_ASC_FILES="${PGP_KEYS_COMMA_DELIMITED_ASC_FILES},${PGP_EXPORTED_ASC_KEY_FILE}"
    fi

    # Increment forward to the next key.
    ITER=$(($ITER + 1))
  done

  echo -e "\033[1;37m\033[41m Listing Secret Keys...\033[0m"
  gpg --list-secret-keys
  echo -e "\033[1;37m\033[41m Listing Public Keys...\033[0m"
  gpg --list-public-keys
  
  printf '%s\n' "$( \
    vault operator init \
    -key-shares=$((n -1)) \
    -key-threshold=$((n - 2)) \
    -root-token-pgp-key=${ROOT_TOKEN_PGP_KEY_ASC_FILE} \
    -pgp-keys=${PGP_KEYS_COMMA_DELIMITED_ASC_FILES} \
  )" > $HOME/.unseal/init.txt

  echo -e "\033[0;32m\033[40m$( cat -n $HOME/.unseal/init.txt )\033[0m"

  local UNSEAL_1_BASE64=$( sed '1q; s/^Unseal Key 1: \(.*\)$/\1/g;' $HOME/.unseal/init.txt )
  echo -e "\033[1;37m\033[41m Attempting Decode of Unseal Key 1...\033[0m"
  echo "${UNSEAL_1_BASE64}" | xxd -r -ps | gpg -d
  # --passphrase $( sed '1q' $HOME/.raw/pgp-key-2-asc-passphrase.raw )
}
pgp_pkill_gpg_agent_daemon() {
  pkill gpg-agent
}