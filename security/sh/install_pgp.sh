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

check_skip_pgp_install () (
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
)

add_pgp_instructions_to_queue () (
  printf '%s\n' \
    pgp_apk_add_packages \
    pgp_create_dir \
    pgp_apply_safe_permissions_to_dir \
    pgp_create_conf \
    pgp_launch_agent \
    pgp_insure_vault_addr_exported \
    pgp_run_vault_server_as_background_process \
    pgp_generate_key_data_init_and_unseal_vault \
    EOP \
    ' ' 1>&3
)

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

pgp_apk_add_packages () (
  # IMPORTANT: Place static tools at the start of the list. <---
  apk_loader $1 \
    busybox-static=1.32.1-r6 \
    apk-tools-static=2.12.5-r0 \
    curl=7.77.0-r0 \
    gnupg=2.2.27-r0 \
    jq=1.6-r1 \
    outils-jot=0.9-r0 \
    vim=8.2.2320-r0
)

pgp_create_dir () (
  [ ! -d $HOME/.gnupg ] && mkdir $HOME/.gnupg
)
pgp_apply_safe_permissions_to_dir () (
  chmod 0700 $HOME/.gnupg
)
pgp_create_conf () (
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
)
pgp_launch_agent () (
  # Run gpg-agent daemon with gpg.conf settings
  gpgconf --launch gpg-agent
)
pgp_insure_vault_addr_exported () (
  [ -z "${VAULT_ADDR}" ] && export VAULT_ADDR="http://127.0.0.1:8200"
)
pgp_run_vault_server_as_background_process () (
  # The below subshell mimics entrypoint of 'vault' Docker image.
  ( \
    /usr/bin/dumb-init \
      /bin/sh \
      /usr/local/bin/docker-entrypoint.sh \
      server & \
  ) > /dev/null 2>&1
)
pgp_generate_key_data_init_and_unseal_vault () (
  ITER=${ITER:-1}
  MAX_ITER=${MAX_ITER:-4}
  # If a second argument exists and is an integer, defer to this user-specified value.
  [ ! -z "${2}" ] && [ -z "$(echo -n "${2}" | sed 's/[0-9]\{1,\}//g')" ] && MAX_ITER=$2

  # Initialize variable to be incremented.
  n=0

  # Start building the payload string used to communicate with ${VAULT_ADDR}/v1/sys/init endpoint.
  VAULT_API_V1_SYS_INIT_JSON="{"

  # Iterate through the PGP keys in the batch.
  while [ $ITER -le $MAX_ITER ]; do
    # Initialize a variable whose value contains a dynamic string padded
    # by leading zeros of length ${#MAX_ITER}
    ITER_STR=$(
      printf '%0'"${#MAX_ITER}"'d' ${ITER}
    )
    # Generate random hexadecimal filename with length of 32 characters.
    # NOTE: This creates a dotfile.
    PGP_BATCH_FILE=${PGP_BATCH_PATH}/.$( \
      tr -cd a-f0-9 < /dev/random | \
      fold -w 32 | \
      head -n 1 \
    )
    # Generate random integer (20 to 99)
    PGP_PHRASE_LEN=$( \
      jot -w %i -r 1 20 99 \
    )
    # Generate random string with length ${PHRASE_LEN}
    PGP_PHRASE=$( \
      utf8_passphrase $PHRASE_LEN \
    )
    # Parse the real name and email from line ${ITER} in the credentials file
    PGP_REAL_EMAIL_NAME="$( \
      sed "${ITER}q;d" /var/tmp/credentials \
    )"

    [ $ITER -eq $MAX_ITER ] && \
    PGP_DONE_MSG="%echo Key Generation: COMPLETE!" || \
    PGP_DONE_MSG="%echo Key ${ITER_STR}: Details Complete."

    # Generate the batch for this specific nth PGP key.
    printf '%s\n' \
      "%echo Generating Key [ $ITER / $MAX_ITER ]" \
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
      "${PGP_DONE_MSG}" > /pgp_batch_file # $PGP_BATCH_FILE

    # Generate the PGP key by running the batch file.
    gpg \
      --expert \
      --verbose \
      --batch \
      --gen-key $PGP_BATCH_FILE

    # Delete the batch file after use.
    rm -f $PGP_BATCH_FILE

    # Capture the base name of most recently generated revocation file.
    PGP_GENERATED_KEY_ID_HEX=$( \
      ls -t ${HOME}/.gnupg/openpgp-revocs.d | \
      head -n 1 | \
      cut -f 1 -d '.' \
    )

    # Parse out the fingerprint of the above key's subkey.
    PGP_ENC_SUB_KEY_ID_HEX=$( \
      gpg \
      --list-keys \
      --with-fingerprint | \
      tr '\n' ' ' | tr -d ' ' | \
      sed "s|[^ ]\{0,\}pubrsa4096/0x${PGP_GENERATED_KEY_ID_HEX:24:16}[^ ]\{1,\}subrsa4096/0x[^ ]\{1,\}Keyfingerprint=\([0-9A-F]\{40\}\)|\1|g"
    )

    # Export the subkey in base64 encoded *.asc format (what Vault consumes).
    # Use tr to get rid of all newlines.
    PGP_BASE64_ONE_LINE_ASC_DATA="$( \
      gpg \
      --verbose \
      --pinentry-mode loopback \
      --passphrase "${PGP_PHRASE}" \
      --export \
      ${PGP_ENC_SUB_KEY_ID_HEX} | \
      base64 | \
      tr -d '\n' \
    )"
    
    # Payload:
    # This is the password protected 32 byte word used to wrap data-at-rest.
    PAYLOAD_PHRASE_LEN=$( \
      jot -w %i -r 1 32 64 \
    )
    PAYLOAD_PHRASE=$( \
      utf8_passphrase $PAYLOAD_PHRASE_LEN \
    )
    PAYLOAD_AES=$( \
      aes-wrap rand 32 \
    )
    # This is PAYLOAD_HEX in upper-case hex format (what aes-wrap/openssl consumes).
    PAYLOAD_HEX=$( \
      echo -n ${PAYLOAD_AES} | \
      hexdump -v -e '/1 "%02X"' \
    )
    
    # Ephemeral:
    # This is the password protected 32 byte word used to wrap payload.
    EPHEMERAL_PHRASE_LEN=$( \
      jot -w %i -r 1 32 64 \
    )
    EPHEMERAL_PHRASE=$( \
      utf8_passphrase $EPHEMERAL_PHRASE_LEN \
    )
    EPHEMERAL_AES=$( \
      aes-wrap rand 32 \
    )
    # This is EPHEMERAL_HEX in upper-case hex format (what aes-wrap/openssl consumes).
    EPHEMERAL_HEX=$( \
      echo -n ${EPHEMERAL_AES} | \
      hexdump -v -e '/1 "%02X"' \
    )

    # Private Key:
    PRIV_KEY_PHRASE_LEN=$( \
      jot -w %i -r 1 32 64 \
    )
    PRIV_KEY_PHRASE=$( \
      utf8_passphrase $PRIV_KEY_PHRASE_LEN \
    )
    PRIV_KEY="$( \
      echo -n ${PRIV_KEY_PHRASE} | \
      aes-wrap genpkey \
        -outform PEM \
        -algorithm RSA \
        -pass stdin \
        -pkeyopt rsa_keygen_bits:4096 \
        -aes256 | \
      tr -d '\n' \
    )"

    # Public Key:
    # This is the password protected public key used to wrap ephemeral.
    PUB_KEY_PHRASE_LEN=$( \
      jot -w %i -r 1 32 64 \
    )
    PUB_KEY_PHRASE=$( \
      utf8_passphrase $PUB_KEY_PHRASE_LEN \
    )
    #
    # Here there be dragons! (are multiple arguments passed this way?)
    #
    PUB_KEY="$( \
      echo -n "${PRIV_KEY}" "${PRIV_KEY_PHRASE}" "${PUB_KEY_PHRASE}" | \
      aes-wrap rsa \
        -inform PEM \
        -passin stdin \
        -outform PEM \
        -pubout \
        -passout stdin \
        -check \
        -aes256 | \
      tr -d '\n' \
    )"
    # Encrypted data-at-rest remains in a networked volume
    DATA_WRAPPED="$( \
      echo -n "${this_should_be_the_exported_pgp_key}" "${PAYLOAD_PHRASE}" | \
      aes-wrap enc \
        -id-aes256-wrap-pad \
        -pass stdin \
        -e \
        -K $PAYLOAD_HEX \
        -iv A65959A6 \
        -md sha512 \
        -iter 250000 | \
      tr -d '\n' \
    )"
    # Wrapped decryption keys are concatenated into a file that is not persisted on the network
    PAYLOAD_WRAPPED="$( \
      echo -n "${this_should_be_the_exported_pgp_key}" "${EPHEMERAL_PHRASE}" | \
      aes-wrap enc \
        -id-aes256-wrap-pad \
        -pass stdin \
        -e \
        -K $EPHEMERAL_HEX \
        -iv A65959A6 \
        -md sha512 \
        -iter 250000 | \
      tr -d '\n' \
    )"
    EPHEMERAL_WRAPPED="$( \
      echo -n "${PUB_KEY}" "${PUB_KEY_PHRASE}" | \
      aes-wrap pkeyutl \
        -encrypt \
        -pubin \
        -passin stdin \
        -pkeyopt rsa_padding_mode:oaep \
        -pkeyopt rsa_oaep_md:sha256 \
        -pkeyopt rsa_mgf1_md:sha1 | \
      tr -d '\n' \
    )"
    printf '%s\n' \
    "${EPHEMERAL_WRAPPED}" \
    "${PAYLOAD_WRAPPED}" \
    "${DATA_WRAPPED}" > appropriately_named_rsa_aes_wrapped_file.bin

    # Increment the value of `n`.
    # IMPORTANT:  We must increment in advance to prevent overrun of
    #             generated key quantity during call of
    #             `vault operator init` below.
    n=$(($n + 1))

    if [ $n -eq 1 ]; then
      # Latch in the exported key data (root token key).
      [ -z "${ROOT_TOKEN_PGP_KEY_ASC_FILE}" ] &&
        ROOT_TOKEN_PGP_KEY_ASC_FILE="${PGP_EXPORTED_ASC_KEY_FILE}"

      # JSON: Append the root token encryption key to payload string.
      VAULT_API_V1_SYS_INIT_JSON="${VAULT_API_V1_SYS_INIT_JSON}\"root_token_pgp_key\":\"$(
        cat ${PGP_EXPORTED_ASC_KEY_FILE} |
          tr -d '\n'
      )\",\"pgp_keys\":["

    elif [ $n -gt 1 ]; then
      # Latch in the exported key data (unseal key shares).
      [ -z "${PGP_KEYS_COMMA_DELIMITED_ASC_FILES}" ] &&
        PGP_KEYS_COMMA_DELIMITED_ASC_FILES="${PGP_EXPORTED_ASC_KEY_FILE}" ||
        PGP_KEYS_COMMA_DELIMITED_ASC_FILES="${PGP_KEYS_COMMA_DELIMITED_ASC_FILES},${PGP_EXPORTED_ASC_KEY_FILE}"

      # Conditionally insert commas, except for final asc key.
      COMMA_STR=${COMMA_STR:-","}
      [ $ITER -eq $MAX_ITER ] && COMMA_STR=

      # JSON: Append the base64 encoded contents of each asc key to payload string.
      VAULT_API_V1_SYS_INIT_JSON="${VAULT_API_V1_SYS_INIT_JSON}\"$(cat ${PGP_EXPORTED_ASC_KEY_FILE} | tr -d '\n')\"${COMMA_STR}"
    fi

    # Increment forward to the next key.
    ITER=$(($ITER + 1))
  done

  # JSON: Append our secret shares to payload string (synonymous with key-shares),
  #       and append our secret threshold to payload string (synonymous with key-threshold).
  VAULT_API_V1_SYS_INIT_JSON="${VAULT_API_V1_SYS_INIT_JSON}],\"secret_shares\":$(($n - 1)),\"secret_threshold\":$(($n - 2))}"

  # JSON: Send our payload string to the ${VAULT_ADDR}/v1/sys/init endpoint.
  curl \
    --request PUT \
    --data "${VAULT_API_V1_SYS_INIT_JSON}" \
    ${VAULT_ADDR}/v1/sys/init |
    jq > /response.txt

  SYS_INIT_KEYS_LINE=-1
  UNSEAL_RESPONSE=
  INITIAL_ROOT_TOKEN=

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
              sed '1q' < ${HOME}/.raw/pgp-key-1-asc-passphrase.raw |
                tr -d '\n'
            )" | tr -d '\n'
      )"

    else
      if [ $SYS_INIT_KEYS_LINE -gt -1 ]; then
        # Decrypt keys.

        UNSEAL_KEY_NUM=$(($n + 1 - $SYS_INIT_KEYS_LINE))
        if [ $UNSEAL_KEY_NUM -le $MAX_ITER ]; then
          UNSEAL_KEY_STR="$(
            echo "${SYS_UNSEAL_LINE}" |
              sed "s/^.*\"\([a-f0-9]\{2,\}\)\"[,]\{0,1\}.*$/\1/g;" |
              xxd -r -ps |
              gpg \
                --pinentry-mode loopback \
                --decrypt \
                --passphrase "$(
                  sed '1q' < ${HOME}/.raw/pgp-key-${UNSEAL_KEY_NUM}-asc-passphrase.raw |
                    tr -d '\n'
                )" | tr -d '\n'
          )"
          JSON_SYS_UNSEAL_PAYLOAD="{\"key\":\"${UNSEAL_KEY_STR}\"}"
          UNSEAL_RESPONSE="$(
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
)
pgp_pkill_gpg_agent_daemon () (
  pkill gpg-agent
)
