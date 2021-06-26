#!/bin/sh

# Name: install_pgp.sh
# Desc: A thorough collection of shell script functions and commands
#       that are necessary for initializing a PGP-hardened instance
#       of HashiCorp Vault on 'alpine:3.13.5' or higher.
#
# NOTE: While these scripts and commands have been authored to be
#       portable wherever possible, this effort is based on current
#       knowledge of POSIX conformance in `/bin/sh`.
#       As such, these scripts can still be improved and should not
#       be considered fully optimized for a given purpose.

check_skip_pgp_install () {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

add_pgp_instructions_to_queue () {
  printf '%s\n' \
    pgp_apk_add_packages \
    pgp_create_dir \
    pgp_apply_safe_permissions_to_dir \
    pgp_create_asc_dir \
    pgp_create_conf \
    pgp_launch_agent \
    pgp_insure_vault_addr_exported \
    pgp_run_vault_server_as_background_process \
    pgp_generate_key_data_init_and_unseal_vault \
    EOP \
    ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

pgp_apk_add_packages () {
  local ARG=$1
  if [ -z "$( echo -n ${ARG} | sed 's|[0-9]\{1,\}||g' )" ]; then
    [ $ARG -eq 0 ] && [ -z "${APK_FLAGS}" ] && local APK_FLAGS='--quiet --no-progress'
    [ $ARG -eq 2 ] && [ -z "${APK_FLAGS}" ] && local APK_FLAGS='--verbose'
  fi
  apk "${APK_FLAGS}" update
  apk --no-cache "${APK_FLAGS}" add \
    busybox-static=1.32.1-r6 \
    apk-tools-static=2.12.5-r0
  apk.static --no-cache "${APK_FLAGS}" add \
    coreutils=8.32-r2 \
    curl=7.77.0-r1 \
    gnupg=2.2.27-r0 \
    imagemagick=7.0.11.13-r0 \
    jq=1.6-r1 \
    outils-jot=0.9-r0 \
    vim=8.2.2320-r0
}

pgp_create_dir () {
  [ ! -d $HOME/.gnupg ] && mkdir $HOME/.gnupg
}
pgp_apply_safe_permissions_to_dir () {
  chmod 0700 $HOME/.gnupg
}
pgp_create_asc_dir () {
  [ ! -d $HOME/.gnupg/asc ] && mkdir $HOME/.gnupg/asc
}
pgp_create_conf () {
  printf '%s\n' \
  '# Prevent information leaks' \
  'no-emit-version' \
  'no-comments' \
  'export-options export-minimal' \
  '' \
  '# Display long format IDs and fingerprints of keys' \
  'keyid-format 0xlong' \
  'with-fingerprint' \
  '' \
  '# Display validity of keys' \
  'list-options show-uid-validity' \
  'verify-options show-uid-validity' \
  '' \
  '# Constrain available algorithms and set preferences' \
  'personal-cipher-preferences AES256' \
  'personal-digest-preferences SHA512' \
  'default-preference-list SHA512 SHA384 SHA256 RIPEMD160 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed' \
  '' \
  'cipher-algo AES256' \
  'digest-algo SHA512' \
  'cert-digest-algo SHA512' \
  'compress-algo ZLIB' \
  '' \
  'disable-cipher-algo 3DES' \
  'weak-digest SHA1' \
  '' \
  's2k-cipher-algo AES256' \
  's2k-digest-algo SHA512' \
  's2k-mode 3' \
  's2k-count 65011712' > $HOME/.gnupg/gpg.conf
}
pgp_launch_agent () {
  # Run gpg-agent daemon with gpg.conf settings
  gpgconf --launch gpg-agent
}
pgp_insure_vault_addr_exported () {
  [ -z "${VAULT_ADDR}" ] && export VAULT_ADDR="http://127.0.0.1:8200"
}
pgp_run_vault_server_as_background_process () {
  # The below subshell mimics entrypoint of 'vault' Docker image.
  ( \
    /usr/bin/dumb-init \
      /bin/sh \
      /usr/local/bin/docker-entrypoint.sh \
      server & \
  ) > /dev/null 2>&1
}
pgp_generate_key_data_init_and_unseal_vault () {
  local ARG=$1
  local ITER=1
  local MAX_ITER=4
  # If a second argument exists and is an integer, defer to this user-specified value.
  [ ! -z "${2}" ] && [ -z "$(echo -n "${2}" | sed 's|[0-9]\{1,\}||g')" ] && MAX_ITER=$2

  # Create the temporary directory where ephemeral batch files are stored.
  local PGP_BATCH_PATH=/tmp/pgp
  [ ! -d $PGP_BATCH_PATH ] && mkdir $PGP_BATCH_PATH

  # Create a string for holding PGP Key passphrases for use inside this function only.
  local PGP_FUNC_SCOPE_ONLY_PHRASES=

  # Create a string for holding our base64 encoded PGP keys for use with JSON.
  local PGP_KEYS_COMMA_DELIMITED_ASC_FILES=

  # Initialize variable to be incremented.
  local n=0

  # Start building the payload string used to communicate with ${VAULT_ADDR}/v1/sys/init endpoint.
  local PGP_KEYS_ROOT_TOKEN_ASC_FILE= #VAULT_API_V1_SYS_INIT_JSON="{"

  local I_PIPE=$( \
    tr -cd a-f0-9 < /dev/random | \
    fold -w 8 | \
    head -n 1 \
  )

  mkfifo $I_PIPE

  local O_PIPE=$( \
    tr -cd a-f0-9 < /dev/random | \
    fold -w 8 | \
    head -n 1 \
  )

  mkfifo $O_PIPE

  # Iterate through the PGP keys in the batch.
  while [ $ITER -le $MAX_ITER ]; do
    # Initialize a variable whose value contains a dynamic string padded
    # by leading zeros of length ${#MAX_ITER}
    local ITER_STR=$(
      printf '%0'"${#MAX_ITER}"'d' "${ITER}"
    )
    echo "ITER_STR = ${ITER_STR}"
    # Generate random hexadecimal filename with length of 32 characters.
    # NOTE: This creates a dotfile.
    local PGP_BATCH_FILE="${PGP_BATCH_PATH}/.$( \
      tr -cd a-f0-9 < /dev/random | \
      fold -w 32 | \
      head -n 1 \
    )"
    echo "PGP_BATCH_FILE = ${PGP_BATCH_FILE}"
    # Generate random integer (20 to 32)
    local PGP_PHRASE_LEN=$( \
      jot -w %i -r 1 20 32 \
    )
    echo "PGP_PHRASE_LEN = ${PGP_PHRASE_LEN}"
    # Generate random string with length ${PHRASE_LEN}
    local PGP_PHRASE=$( \
      utf8_passphrase "${PGP_PHRASE_LEN}" \
    )
    echo "PGP_PHRASE = ${PGP_PHRASE}"
    # Parse the real name and email from line ${ITER} in the credentials file
    local PGP_REAL_EMAIL_NAME="$( \
      sed "${ITER}q;d" /var/tmp/credentials \
    )"
    echo "PGP_REAL_EMAIL_NAME = ${PGP_REAL_EMAIL_NAME}"
    local PGP_REAL_NAME_SLUG=$( \
      echo -n "${PGP_REAL_EMAIL_NAME}" | \
      cut -d ',' -f 1 | \
      tr '[:upper:]' '[:lower:]' | \
      sed 's|[ ]\{1\}|-|g' \
    )
    echo "PGP_REAL_NAME_SLUG = ${PGP_REAL_NAME_SLUG}"

    local PGP_DONE_MSG=
    [ $ITER -eq $MAX_ITER ] && \
    PGP_DONE_MSG="%echo Key Generation: COMPLETE!" || \
    PGP_DONE_MSG="%echo Key ${ITER_STR}: Details Complete."
    echo "PGP_DONE_MSG = ${PGP_DONE_MSG}"

    # Generate the batch for this specific nth PGP key.
    printf '%s\n' \
      "%echo Generating Key [ ${ITER} / ${MAX_ITER} ]" \
      "Key-Type: RSA" \
      "Key-Length: 4096" \
      "Key-Usage: cert" \
      "Subkey-Type: RSA" \
      "Subkey-Length: 4096" \
      "Subkey-Usage: encrypt" \
      "Passphrase: ${PGP_PHRASE}" \
      "Name-Real: $( echo -n "${PGP_REAL_EMAIL_NAME}" | cut -d ',' -f 1 )" \
      "Name-Email: $( echo -n "${PGP_REAL_EMAIL_NAME}" | cut -d ',' -f 2 )" \
      "Expire-Date: 0" \
      "%commit" \
      "${PGP_DONE_MSG}" > "${PGP_BATCH_FILE}"
    echo -e "PGP_BATCH_FILE:\n$( cat -n $PGP_BATCH_FILE )"

    # Generate the PGP key by running the batch file.
    gpg \
      --expert \
      --verbose \
      --batch \
      --gen-key "${PGP_BATCH_FILE}"
    echo "Exported PGP key using gen-key."

    # Delete the batch file after use.
    rm -f "${PGP_BATCH_FILE}"
    echo "Rim forced batch file."

    if [ $ARG -eq 2 ]; then
      echo -e "\033[1;33m\033[40m * * * Building Entropy Image JPEG for PGP Key ${ITER}. \033[0m"
      echo -e "\033[1;33m\033[40m * * * WARNING: This process takes a very long time. \033[0m"
    fi

    # Create an entropy image for the PGP key.
    local ENTROPY_IMAGE_PATH=$( \
      get_earthcam_entropy_image \
      "$(( ( $ITER - 1 ) * 3 ))" \
      "${PGP_REAL_NAME_SLUG}" \
    )
    echo "ENTROPY_IMAGE_PATH = ${ENTROPY_IMAGE_PATH}"

    echo "before: gpg addphoto" # debug
    # Add the entropy image to our generated key:
    ( \
      echo "addphoto"; \
      echo "${ENTROPY_IMAGE_PATH}"; \
      echo "y"; \
      echo "${PGP_PHRASE}"; \
      echo "save"; \
    ) | gpg \
      --no-tty \
      --command-fd=0 \
      --status-fd=1 \
      --pinentry-mode=loopback \
      --edit-key "$( \
        echo -n "${PGP_REAL_EMAIL_NAME}" | \
        cut -d ',' -f 2 \
      )"
    echo "after: gpg addphoto" # debug

    # Capture the base name of most recently generated revocation file.
    local PGP_GENERATED_KEY_ID_HEX=$( \
      ls -t ${HOME}/.gnupg/openpgp-revocs.d | \
      head -n 1 | \
      cut -f 1 -d '.' \
    )
    echo "PGP_GENERATED_KEY_ID_HEX = ${PGP_GENERATED_KEY_ID_HEX}"

    # Parse out the fingerprint of the above key's subkey.
    local PGP_ENC_SUB_KEY_ID_HEX=$( \
      gpg \
      --list-keys \
      --with-fingerprint | \
      tr '\n' ' ' | tr -d ' ' | \
      sed "s|[^ ]\{0,\}pubrsa4096/0x${PGP_GENERATED_KEY_ID_HEX:24:16}[^ ]\{1,\}subrsa4096/0x[^ ]\{1,\}Keyfingerprint=\([0-9A-F]\{40\}\)|\1|g"
    )
    echo "PGP_ENC_SUB_KEY_ID_HEX = ${PGP_ENC_SUB_KEY_ID_HEX}"

    # Export the subkey in base64 encoded *.asc format (what Vault consumes).
    local PGP_EXPORTED_KEY_ASC_FILE="${HOME}/.gnupg/asc/${PGP_REAL_NAME_SLUG}.asc"
    gpg \
    --verbose \
    --pinentry-mode loopback \
    --passphrase "${PGP_PHRASE}" \
    --export "${PGP_ENC_SUB_KEY_ID_HEX}" | \
    base64 > "${PGP_EXPORTED_KEY_ASC_FILE}"

    local DATA_TO_WRAP="$( \
      cat "${PGP_EXPORTED_KEY_ASC_FILE}" | \
      tr -d '\n' \
    )"
    echo "DATA_TO_WRAP = ${DATA_TO_WRAP}"

    # Place each PGP key's passphrase into our function scoped string.
    [ -z "${PGP_FUNC_SCOPE_ONLY_PHRASES}" ] && \
    PGP_FUNC_SCOPE_ONLY_PHRASES="${PGP_PHRASE}" || \
    PGP_FUNC_SCOPE_ONLY_PHRASES="${PGP_FUNC_SCOPE_ONLY_PHRASES} ${PGP_PHRASE}"
    echo "PGP_FUNC_SCOPE_ONLY_PHRASES = ${PGP_FUNC_SCOPE_ONLY_PHRASES}"
    
    # Payload:
    # This is the password protected 32 byte word used to wrap data-at-rest.
    local PAYLOAD_PHRASE_LEN=$( \
      jot -w %i -r 1 20 32 \
    )
    echo "PAYLOAD_PHRASE_LEN = ${PAYLOAD_PHRASE_LEN}"
    local PAYLOAD_PHRASE=$( \
      utf8_passphrase "${PAYLOAD_PHRASE_LEN}" \
    )
    echo "PAYLOAD_PHRASE = ${PAYLOAD_PHRASE}"
    local PAYLOAD_AES=$( \
      aes-wrap rand 32 \
    )
    echo "PAYLOAD_AES = ${PAYLOAD_AES}"
    # This is PAYLOAD_HEX in upper-case hex format (what aes-wrap/openssl consumes).
    local PAYLOAD_HEX=$( \
      echo -n "${PAYLOAD_AES}" | \
      hexdump -v -e '/1 "%02X"' \
    )
    echo "PAYLOAD_HEX = ${PAYLOAD_HEX}"
    local PAYLOAD_TO_WRAP=$( \
      encode_data_at_rest \
      "${PAYLOAD_AES}" \
      "${PAYLOAD_PHRASE}" | \
      base64 | \
      tr -d '\n' \
    )
    echo "PAYLOAD_TO_WRAP = ${PAYLOAD_TO_WRAP}"
    
    # Ephemeral:
    # This is the password protected 32 byte word used to wrap payload.
    local EPHEMERAL_PHRASE_LEN=$( \
      jot -w %i -r 1 20 32 \
    )
    echo "EPHEMERAL_PHRASE_LEN = ${EPHEMERAL_PHRASE_LEN}"
    local EPHEMERAL_PHRASE=$( \
      utf8_passphrase "${EPHEMERAL_PHRASE_LEN}" \
    )
    echo "EPHEMERAL_PHRASE = ${EPHEMERAL_PHRASE}"
    local EPHEMERAL_AES=$( \
      aes-wrap rand 32 \
    )
    echo "EPHEMERAL_AES = ${EPHEMERAL_AES}"
    # This is EPHEMERAL_HEX in upper-case hex format (what aes-wrap/openssl consumes).
    local EPHEMERAL_HEX=$( \
      echo -n "${EPHEMERAL_AES}" | \
      hexdump -v -e '/1 "%02X"' \
    )
    echo "EPHEMERAL_HEX = ${EPHEMERAL_HEX}"
    local EPHEMERAL_TO_WRAP=$( \
      encode_data_at_rest \
      "${EPHEMERAL_AES}" \
      "${EPHEMERAL_PHRASE}" | \
      base64 | \
      tr -d '\n' \
    )
    echo "EPHEMERAL_TO_WRAP = ${EPHEMERAL_TO_WRAP}"

    # Private Key:
    local PRIV_KEY_PHRASE_LEN=$( \
      jot -w %i -r 1 20 255 \
    )
    echo "PRIV_KEY_PHRASE_LEN = ${PRIV_KEY_PHRASE_LEN}"
    local PRIV_KEY_PHRASE=$( \
      utf8_passphrase "${PRIV_KEY_PHRASE_LEN}" \
    )
    echo "PRIV_KEY_PHRASE = ${PRIV_KEY_PHRASE}"
    ( echo -n "${PRIV_KEY_PHRASE}" > $I_PIPE & ) 2>&1 >/dev/null
    local PRIV_KEY="$( \
      aes-wrap genpkey \
        -outform PEM \
        -algorithm RSA \
        -pass file:${I_PIPE} \
        -pkeyopt rsa_keygen_bits:4096 \
        -aes256 | \
      base64 | \
      tr -d '\n' \
    )"
    echo "PRIV_KEY = $( echo "${PRIV_KEY}" | base64 -d )"

    # Public Key:
    # This is the password protected public key used to wrap ephemeral.
    local PUB_KEY_PHRASE_LEN=$( \
      jot -w %i -r 1 20 255 \
    )
    echo "PUB_KEY_PHRASE_LEN = ${PUB_KEY_PHRASE_LEN}"
    local PUB_KEY_PHRASE=$( \
      utf8_passphrase "${PUB_KEY_PHRASE_LEN}" \
    )
    echo "PUB_KEY_PHRASE = ${PUB_KEY_PHRASE}"
    ( echo -n "${PRIV_KEY_PHRASE}" > $I_PIPE & ) 2>&1 >/dev/null
    ( echo -n "${PUB_KEY_PHRASE}" > $O_PIPE & ) 2>&1 >/dev/null
    local PUB_KEY="$( \
      echo -n "${PRIV_KEY}" | \
      base64 -d | \
      aes-wrap rsa \
        -inform PEM \
        -passin file:${I_PIPE} \
        -outform PEM \
        -pubout \
        -passout file:${O_PIPE} \
        -check \
        -aes256 | \
      base64 | \
      tr -d '\n' \
    )"
    echo "PUB_KEY = $( echo "${PUB_KEY}" | base64 -d )"
    # Encrypted data-at-rest remains in a networked volume
    ( echo -n ${PAYLOAD_PHRASE} > $I_PIPE & ) 2>&1 >/dev/null
    local DATA_WRAPPED="$( \
      echo -n "${DATA_TO_WRAP}" | \
      aes-wrap enc \
        -id-aes256-wrap-pad \
        -pass file:${I_PIPE} \
        -e \
        -K "${PAYLOAD_HEX}" \
        -iv A65959A6 \
        -md sha512 \
        -iter 250000 | \
      base64 | \
      tr -d '\n' \
    )"
    echo "DATA_WRAPPED = $( echo "${DATA_WRAPPED}" | base64 -d )"
    # Wrapped decryption keys are concatenated into a file that is not persisted on the network
    ( echo -n ${EPHEMERAL_PHRASE} > $I_PIPE & ) 2>&1 >/dev/null
    local PAYLOAD_WRAPPED="$( \
      echo -n "${PAYLOAD_TO_WRAP}}" | \
      base64 -d | \
      aes-wrap enc \
        -id-aes256-wrap-pad \
        -pass file:${I_PIPE} \
        -e \
        -K "${EPHEMERAL_HEX}" \
        -iv A65959A6 \
        -md sha512 \
        -iter 250000 | \
      base64 | \
      tr -d '\n' \
    )"
    echo "PAYLOAD_WRAPPED = $( echo "${PAYLOAD_WRAPPED}" | base64 -d )"
    ( echo -n ${PUB_KEY_PHRASE} > $I_PIPE & ) 2>&1 >/dev/null
    local EPHEMERAL_WRAPPED="$( \
      echo -n "${EPHEMERAL_TO_WRAP}" | \
      base64 -d | \
      aes-wrap pkeyutl \
        -encrypt \
        -pubin \
        -inkey "$( echo -n "${PUB_KEY}" | base64 -d )" \
        -passin file:${I_PIPE} \
        -pkeyopt rsa_padding_mode:oaep \
        -pkeyopt rsa_oaep_md:sha256 \
        -pkeyopt rsa_mgf1_md:sha1 | \
      base64 | \
      tr -d '\n' \
    )"
    echo "EPHEMERAL_WRAPPED = ${EPHEMERAL_WRAPPED}"
    # Send our encoded, wrapped strings to the destination file.
    printf '%s\n' \
    "${EPHEMERAL_WRAPPED}" \
    "${PAYLOAD_WRAPPED}" \
    "${DATA_WRAPPED}" > "${PGP_REAL_NAME_SLUG}.bin"
    echo -e "${PGP_REAL_NAME_SLUG}.bin:\n$( cat -n "${PGP_REAL_NAME_SLUG}.bin" )"

    local TMP_ENTROPY_1="$( aes-wrap rand 32 )"
    echo "TMP_ENTROPY_1 = ${TMP_ENTROPY_1}"
    local TMP_ENTROPY_2="$( aes-wrap rand 32 )"
    echo "TMP_ENTROPY_2 = ${TMP_ENTROPY_2}"

    # Warn the user this is their FIRST, LAST, AND ONLY CHANCE to copy down the information being displayed.
    echo -e "\033[1;31m\033[47m !! IMPORTANT !!         !! IMPORTANT !!         !! IMPORTANT !!         !! IMPORTANT !!  \033[0m"
    echo -e "\033[1;31m\033[47m The following data is highly sensitive. It has been custom encoded for security reasons. \033[0m"
    echo -e "\033[1;31m\033[47m THIS DATA WILL NOT BE PERSISTED. THIS IS YOUR FIRST, LAST, AND ONLY CHANCE TO COPY IT.   \033[0m"
    echo -e "\033[0;30m\033[47m - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  \033[0m"
    echo -e "\033[1;31m\033[47m PLEASE COPY AND SECURE THIS DATA TO PREVENT UNRECOVERABLE CRITICAL DATA LOSS.            \033[0m"
    echo ""
    echo -e "\033[0;33m\033[40m $( \
      encode_data_at_rest \
      "${TMP_ENTROPY_1}" \
      "${PUB_KEY_PHRASE}" | \
      base64 | \
      tr -d '\n' \
    ) \033[0m"
    echo ""

    echo -e "\033[1;31m\033[47m !! IMPORTANT !!         !! IMPORTANT !!         !! IMPORTANT !!         !! IMPORTANT !!  \033[0m"
    echo -e "\033[1;31m\033[47m The following data is highly sensitive. It has been custom encoded for security reasons. \033[0m"
    echo -e "\033[1;31m\033[47m THIS DATA WILL NOT BE PERSISTED. THIS IS YOUR FIRST, LAST, AND ONLY CHANCE TO COPY IT.   \033[0m"
    echo -e "\033[0;30m\033[47m - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  \033[0m"
    echo -e "\033[1;31m\033[47m PLEASE COPY AND SECURE THIS DATA TO PREVENT UNRECOVERABLE CRITICAL DATA LOSS.            \033[0m"
    echo ""
    echo -e "\033[0;33m\033[40m $( \
      encode_data_at_rest \
      "${TMP_ENTROPY_2}" \
      "${PGP_PHRASE}" | \
      base64 | \
      tr -d '\n' \
    ) \033[0m"
    echo ""

    # Increment the value of `n`.
    # IMPORTANT:  We must increment in advance to prevent overrun of
    #             generated key quantity during call of
    #             `vault operator init` below.
    n=$(( $n + 1 ))

    if [ $n -eq 1 ]; then
      # JSON: Append the root token encryption key to payload string.
      PGP_KEYS_ROOT_TOKEN_ASC_FILE="${PGP_EXPORTED_KEY_ASC_FILE}"
    elif [ $n -gt 1 ]; then
      # Latch in the exported key data (unseal key shares).
      [ -z "${PGP_KEYS_COMMA_DELIMITED_ASC_FILES}" ] &&
        PGP_KEYS_COMMA_DELIMITED_ASC_FILES="\"${PGP_EXPORTED_KEY_ASC_FILE}\"" ||
        PGP_KEYS_COMMA_DELIMITED_ASC_FILES="${PGP_KEYS_COMMA_DELIMITED_ASC_FILES},\"${PGP_EXPORTED_KEY_ASC_FILE}\""
    fi

    # Increment forward to the next key.
    ITER=$(( $ITER + 1 ))
  done

  # Erase all entropy images.
  # rm -rf $HOME/.gnupg/images

  # JSON: Append our secret shares to payload string (synonymous with key-shares),
  #       and append our secret threshold to payload string (synonymous with key-threshold).
  VAULT_API_V1_SYS_INIT_JSON="${VAULT_API_V1_SYS_INIT_JSON}],\"secret_shares\":$(($n - 1)),\"secret_threshold\":$(($n - 2))}"

  vault operator init \
    -key-shares=$(( $n - 1 )) \
    -key-threshold=$(( $n - 2 )) \
    -root-token-pgp-key="${PGP_KEYS_ROOT_TOKEN_ASC_FILE}"
    -pgp-keys="${PGP_KEYS_COMMA_DELIMITED_ASC_FILES}" > /response.txt
    # UPDATE to official file path.

  local SYS_INIT_KEYS_LINE=-1
  local UNSEAL_RESPONSE=
  local INITIAL_ROOT_TOKEN=

  n=0 # Reset value of 'n'.

  while IFS= read SYS_UNSEAL_LINE; do
    n=$(($n + 1))

    if [ ! -z "$(echo "${SYS_UNSEAL_LINE}" | grep -o '"keys":')" ]; then
      # Record the line number where the 'keys' field is located.
      [ $SYS_INIT_KEYS_LINE -eq -1 ] && SYS_INIT_KEYS_LINE=$n

    elif [ ! -z "$(echo "${SYS_UNSEAL_LINE}" | grep -o '],')" ]; then
      # Delete the line number.
      [ $SYS_INIT_KEYS_LINE -gt -1 ] && SYS_INIT_KEYS_LINE=-1

    elif [ ! -z "$(echo "${SYS_UNSEAL_LINE}" | grep -o '"root_token":')" ]; then
      # Decrypt the initial root token.
      INITIAL_ROOT_TOKEN="$(
        echo "${SYS_UNSEAL_LINE}" |
          sed "s/^.*\"root_token\":.*\"\([^ ]\{4,\}\)\".*$/\1/g" |
          base64 -d |
          gpg \
            --pinentry-mode loopback \
            --decrypt \
            --passphrase "$(
              echo -n "${PGP_FUNC_SCOPE_ONLY_PHRASES}" | cut -f 1 \
            )" | tr -d '\n'
      )"

    else
      if [ $SYS_INIT_KEYS_LINE -gt -1 ]; then
        # Decrypt keys.

        local UNSEAL_KEY_NUM=$(( $n + 1 - $SYS_INIT_KEYS_LINE ))
        if [ $UNSEAL_KEY_NUM -le $MAX_ITER ]; then
          local UNSEAL_KEY_STR="$(
            echo "${SYS_UNSEAL_LINE}" |
              sed "s/^.*\"\([a-f0-9]\{2,\}\)\"[,]\{0,1\}.*$/\1/g;" |
              xxd -r -ps |
              gpg \
                --pinentry-mode loopback \
                --decrypt \
                --passphrase "$(
                  echo -n "${PGP_FUNC_SCOPE_ONLY_PHRASES}" | cut -f ${UNSEAL_KEY_NUM} \
                )" | tr -d '\n'
          )"
          local JSON_SYS_UNSEAL_PAYLOAD="{\"key\":\"${UNSEAL_KEY_STR}\"}"
          local UNSEAL_RESPONSE="$(
            curl \
              --request PUT \
              --data "${JSON_SYS_UNSEAL_PAYLOAD}" \
              ${VAULT_ADDR}/v1/sys/unseal |
              tr -d '\n'
          )"

        else
          echo -e "\033[1;31m\033[47m Number of Key Shares Exceeded! \033[0m"
        fi
      fi
      if [ ! -z "$(echo ${UNSEAL_RESPONSE} | grep -o '0,')" ] &&
        [ ! -z "${INITIAL_ROOT_TOKEN}" ]; then
        # Display our results once Vault is unsealed and the initial root token has been decrypted.
        echo -e "\033[0;37m\033[43m$(echo "${UNSEAL_RESPONSE}" | jq)\033[0m"
        echo -e "\033[1;33m\033[40mThe Initial Root Token is:\033[0;33m\033[40m\n${INITIAL_ROOT_TOKEN}\033[0m\n"
        break

      fi
    fi
  done < response.txt
  # UPDATE to use official file path.
}
pgp_pkill_gpg_agent_daemon () {
  pkill gpg-agent
}
