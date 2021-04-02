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
  pgp_generate_asc_key_data \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

pgp_apk_add_packages() {
  pretty "Adding Packages Using APK..."
  apk add \
    busybox-static \
    apk-tools-static && \
  apk.static add \
    gnupg \
    outils-jot \
    pinentry-gtk
  [ $? -eq 0 ] && \
  pretty --passed || \
  pretty --failed
}

pgp_generate_asc_key_data() {
  # Default value is 4, but can be adjusted using $1 argument.
  local MAX_ITER=${1:-4}
  local ITER=1

  # Create a directory dedicated to the raw files.
  local PGP_SRC_PATH=$HOME/pgp_raw_files && [ ! -d "${PGP_SRC_PATH}" ] && mkdir -m 0700 $PGP_SRC_PATH
  # Create a directory dedicated to the encrypted (wrapped) files.
  local PGP_DST_PATH=$HOME/pgp_enc_files && [ ! -d "${PGP_DST_PATH}" ] && mkdir -m 0700 $PGP_DST_PATH

  # Run a background process that corrects pinentry failures in GnuPG.
  gpg-agent --daemon --pinentry-program pinentry-gtk

  # Iterate through the PGP keys in the batch.
  while [ $ITER -le $MAX_ITER ]; do
    local BATCH_FILE=${BATCH_PATH}/.$(tr -cd a-f0-9 < /dev/urandom | fold -w32 | head -n1)
    local PHRASE_LEN=$(jot -w %i -r 1 20 99)
    local PHRASE=$(tr -cd [[:alnum:][:punct:]] < /dev/urandom | fold -w${PHRASE_LEN} | head -n1)
    local ITER_STR=$(printf '%0'"${#MAX_ITER}"'d' ${ITER})
    local DONE_MSG=
    [ $ITER -eq $MAX_ITER ] && DONE_MSG="%echo Done!" || DONE_MSG="%echo Key Details Complete."

    # Generate the payload AES file.
    $OPENSSL_V111 rand -out ${PGP_SRC_PATH}/payload-aes-${ITER_STR}.bin 32
    # Store hex string of payload.
    local PAYLOAD_HEX=$(hexdump -v -e '/1 "%02X"' < ${PGP_SRC_PATH}/payload-aes-${ITER_STR}.bin)
    
    # Generate the ephemeral AES file.
    $OPENSSL_V111 rand -out ${PGP_SRC_PATH}/ephemeral-aes-${ITER_STR}.bin 32
    # Store hex string of ephemeral.
    local EPHEMERAL_HEX=$(hexdump -v -e '/1 "%02X"' < ${PGP_SRC_PATH}/ephemeral-aes-${ITER_STR}.bin)

    # * * * * *

    # Generate length of passphrase for private key.
    local PRIVATE_KEY_PHRASE_LEN=$(jot -w %i -r 1 32 64)
    # Generate passphrase for private key.
    local PRIVATE_KEY_PASS_PHRASE=$(tr -cd [[:alnum:][:punct:]] < /dev/random | fold -w${PRIVATE_KEY_PHRASE_LEN} | head -n1)
    # Persist passphrase to file.
    echo "${PRIVATE_KEY_PASS_PHRASE}" > ${PGP_SRC_PATH}/private-key-${ITER_STR}-passphrase

    # Generate private key.
    $OPENSSL_V111 genpkey \
    -out ${PGP_DST_PATH}/id-aes256-wrap-pad-private-key-${ITER_STR}.pem \
    -outform PEM \
    -pass ${PGP_SRC_PATH}/private-key-${ITER_STR}-passphrase \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096

    # * * * * *

    # Generate length of passphrase for public key.
    local PUBLIC_KEY_PHRASE_LEN=$(jot -w %i -r 1 32 64)
    # Generate passphrase for public key.
    local PUBLIC_KEY_PASS_PHRASE=$(tr -cd [[:alnum:][:punct:]] < /dev/random | fold -w${PUBLIC_KEY_PHRASE_LEN} | head -n1)
    # Persist passphrase to file.
    echo "${PUBLIC_KEY_PASS_PHRASE}" > ${PGP_SRC_PATH}/public-key-${ITER_STR}-passphrase

    # Generate public key.
    $OPENSSL_V111 rsa \
    -inform PEM \
    -in ${PGP_DST_PATH}/id-aes256-wrap-pad-private-key-${ITER_STR}.pem \
    -outform PEM \
    -out ${PGP_DST_PATH}/id-aes256-wrap-pad-public-key-${ITER_STR}.pem \
    -passout file:${PGP_SRC_PATH}/public-key-${ITER_STR}-passphrase \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096

    # * * * * *

    # Persist passphrase of PGP key to file.
    echo "${PHRASE}" > ${PGP_SRC_PATH}/pgp-key-${ITER_STR}-asc-passphrase.raw

    # Encrypt the PGP key's passphrase file using the payload.
    $OPENSSL_V111 enc \
    -id-aes256-wrap-pad \
    -K $PAYLOAD_HEX \
    -iv A65959A6 \
    -in ${PGP_SRC_PATH}/pgp-key-${ITER_STR}-asc-passphrase.raw \
    -out ${PGP_DST_PATH}/pgp-key-${ITER_STR}-asc-passphrase.wrapped

    # * * * * *

    # Wrap the payload in the ephemeral.
    $OPENSSL_V111 enc \
    -id-aes256-wrap-pad \
    -K $EPHEMERAL_HEX \
    -iv A65959A6 \
    -in ${PGP_SRC_PATH}/payload-aes-${ITER_STR}.bin \
    -out ${PGP_DST_PATH}/payload-aes-${ITER_STR}.wrapped \

    # Wrap the ephemeral in the public key.
    $OPENSSL_V111 pkeyutl \
    -encrypt \
    -in ${PGP_SRC_PATH}/ephemeral-aes-${ITER_STR}.bin \
    -out ${PGP_DST_PATH}/ephemeral-aes-${ITER_STR}.wrapped \
    -pubin \
    -inkey ${PGP_DST_PATH}/id-aes256-wrap-pad-private-key-${ITER_STR}.pem \
    -pkeyopt rsa_padding_mode:oaep \
    -pkeyopt rsa_oaep_md:sha1 \
    -pkeyopt rsa_mgf1_md:sha1

    # * * * * *

    # Concatenate the wrapped ephemeral and payload into one main file.
    cat \
    ${PGP_DST_PATH}/ephemeral-aes-${ITER_STR}.wrapped \
    ${PGP_DST_PATH}/payload-aes-${ITER_STR}.wrapped > ${PGP_DST_PATH}/rsa-aes-wrapped-${ITER_STR}.bin
    # This *.bin file can be safely distributed, but be careful with the
    # corresponding private key!

    # Generate the batch for this specific PGP key.
    printf '%s\n' \
      "%echo Generating Key [ $ITER / $MAX_ITER ]" \
      "Key-Type: default" \
      "Key-Length: 4096" \
      "Subkey-Type: default" \
      "Subkey-Length: 4096" \
      "Passphrase: ${PHRASE}" \
      "Name-Real: ${name_real:-Thomas Tester}" \
      "Name-Email: ${name_email:-test@thesupertask.com}" \
      "Name-Comment: ${name_comment:-Auto-generated Key Used for Testing.}" \
      "Expire-Date: 1y" \
      "%commit" \
    "${DONE_MSG}" >> $BATCH_FILE

    # Generate the PGP key by running the batch file.
    gpg \
    --pinentry-mode loopback \
    --verbose \
    --batch \
    --gen-key $BATCH_FILE

    # Prevent asynchronous code from creating a race condition
    # by sleeping for one second.
    sleep 1s # .............. SLEEP

    # Delete the batch file after use.
    rm -f $BATCH_FILE

    # Capture the most recently generated revocation file.
    # We need to parse its hexadecimal filename to export the key as an ASC file.
    local REVOC_FILE="$(ls -t ${HOME}/.gnupg/openpgp-revocs.d | head -n1)"
    local KEY_ID_HEX="$(basename ${REVOC_FILE} | cut -f1 -d '.')"

    # Export the key in base64 encoded *.asc format (what Vault consumes).
    gpg \
    --export \
    ${KEY_ID_HEX} | \
    base64 > "${PUB_KEYS_PATH}/key_${ITER_STR}.asc"

    # Increment forward to the next key.
    ITER=$(($ITER + 1))
  done

  # Shut down background process (no longer needed).
  pkill gpg-agent
}