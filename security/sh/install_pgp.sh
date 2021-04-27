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
  pgp_generate_key_data_init_and_unseal_vault \
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
    jq \
    outils-jot \
    vim
}
pgp_create_home_directories() {
  # Where data encrypted with id-aes256-wrap-pad will be stored.
  local HOME_WRAPPED_PATH=${HOME_WRAPPED_PATH:-$HOME/.wrapped}
  [ ! -d "${HOME_WRAPPED_PATH}" ] && \
    mkdir -pm 0700 "${HOME_WRAPPED_PATH}" && \
    chown root:root "${HOME_WRAPPED_PATH}"

  # Where response data from `vault init` used to unseal Vault will be stored.
  local HOME_UNSEAL_PATH=${HOME_UNSEAL_PATH:-$HOME/.unseal}
  [ ! -d "${HOME_UNSEAL_PATH}" ] && \
    mkdir -pm 0700 "${HOME_UNSEAL_PATH}" && \
    chown root:root "${HOME_UNSEAL_PATH}"

  # Where unencrypted data will be stored.
  local HOME_RAW_PATH=${HOME_RAW_PATH:-$HOME/.raw}
  [ ! -d "${HOME_RAW_PATH}" ] && \
    mkdir -pm 0700 "${HOME_RAW_PATH}" && \
    chown root:root "${HOME_RAW_PATH}"

  # Where encrypted data will be stored.
  local HOME_ENC_PATH=${HOME_ENC_PATH:-$HOME/.enc}
  [ ! -d "${HOME_ENC_PATH}" ] && \
    mkdir -pm 0700 "${HOME_ENC_PATH}" && \
    chown root:root "${HOME_ENC_PATH}"
}
pgp_start_gpg_agent_as_daemon() {
  gpg-agent --daemon
}
pgp_insure_vault_addr_exported() {
  [ -z "${VAULT_ADDR}" ] && export VAULT_ADDR="http://127.0.0.1:8200"
}
pgp_run_vault_server_as_background_process() {
  ( \
    /usr/bin/dumb-init \
    /bin/sh \
    /usr/local/bin/docker-entrypoint.sh \
    server & \
  ) >/dev/null 2>&1
}
pgp_generate_key_data_init_and_unseal_vault() {
  # The starting iteration to generate is always 1.
  local ITER=${ITER:-1}
  # Default max number of keys to generate is 4.
  local MAX_ITER=${MAX_ITER:-4}
  # If a second argument exists and is an integer, defer to this user-specified value.
  [ ! -z "${2}" ] && [ -z "$( echo -n "${2}" | sed 's/[0-9]\{1,\}//g' )"] && MAX_ITER=$2

  # These are paths to PGP keys required by the `vault operator init` CLI command.
  local ROOT_TOKEN_PGP_KEY_ASC_FILE=
  local PGP_KEYS_COMMA_DELIMITED_ASC_FILES=
  

  # export OPENSSL_V111=$HOME/local/bin/openssl.sh

  # # Create a directory dedicated to the raw files.
  # local PGP_SRC_PATH=$HOME/pgp_raw_files
  # mkdir -pm 0700 $PGP_SRC_PATH
  
  # # Create a directory dedicated to the encrypted (wrapped) files.
  # local PGP_DST_PATH=$HOME/pgp_enc_files
  # mkdir -pm 0700 $PGP_DST_PATH

  # This value is used inside the loop(s) below to assign path strings to the above file paths.
  local n=0
  # JSON: Start building the payload string used to communicate with $(VAULT_ADDR}/v1/sys/init endpoint.
  local JSON_SYS_INIT_PAYLOAD="{"

  # Iterate through the PGP keys in the batch.
  while [ $ITER -le $MAX_ITER ]; do
    # Initialize a variable whose value contains a dynamic string whose padded
    # leading zeros are derived from the character length of $MAX_ITER.
    local ITER_STR=$( \
      printf '%0'"${#MAX_ITER}"'d' ${ITER} \
    )
    # Generate random hexadecimal filename with length of 32 characters.
    local BATCH_FILE=${BATCH_PATH}/.$( \
      tr -cd a-f0-9 < /dev/random | \
      fold -w32 | \
      head -n 1 \
    )

    # Generate random integer in the range (20, 99).
    local PHRASE_LEN=$( \
      jot -w %i -r 1 20 99 \
    )

    # Generate random passphrase with random length of ${PHRASE_LEN}.
    local PHRASE=$( \
      tr -cd [[:alnum:][:punct:]] < /dev/random | \
      fold -w${PHRASE_LEN} | \
      head -n 1 \
    )

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
    echo -n "${PHRASE}" > $HOME/.raw/pgp-key-${ITER_STR}-asc-passphrase.raw

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

    local DONE_MSG=${DONE_MSG:-"%echo Key Details Complete."}
    [ $ITER -eq $MAX_ITER ] && DONE_MSG="%echo Done!"

    # Generate the batch for this specific PGP key.
    # TODO: Remove tester email and real name.
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
    --verbose \
    --batch \
    --gen-key $BATCH_FILE

    # Delete the batch file after use.
    rm -f $BATCH_FILE

    # Capture the most recently generated revocation file.
    # We need to parse its hexadecimal filename to export the key as an ASC file.
    local PGP_GENERATED_KEY_ID_HEX=$( \
      ls -t ${HOME}/.gnupg/openpgp-revocs.d | \
      head -n 1 | \
      cut -f 1 -d '.' \
    )

    local PGP_EXPORTED_ASC_KEY_FILE="${PGP_DST_PATH}/key_${ITER_STR}.asc"

    # Export the key in base64 encoded *.asc format (what Vault consumes).
    # Use tr to get rid of all newlines.
    gpg \
    --verbose \
    --pinentry-mode loopback \
    --passphrase "$( \
      cat $HOME/.raw/pgp-key-${ITER_STR}-asc-passphrase.raw | \
      tr -d '\n' \
    )" \
    --export-secret-keys \
    ${PGP_GENERATED_KEY_ID_HEX} | \
    base64 | \
    tr -d '\n' > ${PGP_EXPORTED_ASC_KEY_FILE}

    # Increment the value of `n`.
    # IMPORTANT:  We must increment in advance to prevent overrun of
    #             generated key quantity during call of
    #             `vault operator init` below.
    n=$(($n + 1))

    if [ $n -eq 1 ]; then
      # Latch in the exported key data (root token key).
      [ -z "${ROOT_TOKEN_PGP_KEY_ASC_FILE}" ] && \
      ROOT_TOKEN_PGP_KEY_ASC_FILE="${PGP_EXPORTED_ASC_KEY_FILE}"

      # JSON: Append the root token encryption key to payload string.
      JSON_SYS_INIT_PAYLOAD="${JSON_SYS_INIT_PAYLOAD}\"root_token_pgp_key\":\"$( \
        cat ${PGP_EXPORTED_ASC_KEY_FILE} | \
        tr -d '\n' \
      )\",\"pgp_keys\":["

    elif [ $n -gt 1 ]; then
      # Latch in the exported key data (unseal key shares).
      [ -z "${PGP_KEYS_COMMA_DELIMITED_ASC_FILES}" ] && \
      PGP_KEYS_COMMA_DELIMITED_ASC_FILES="${PGP_EXPORTED_ASC_KEY_FILE}" || \
      PGP_KEYS_COMMA_DELIMITED_ASC_FILES="${PGP_KEYS_COMMA_DELIMITED_ASC_FILES},${PGP_EXPORTED_ASC_KEY_FILE}"

      # Conditionally insert commas, except for final asc key.
      local COMMA_STR=${COMMA_STR:-","}
      [ $ITER -eq $MAX_ITER ] && COMMA_STR=

      # JSON: Append the base64 encoded contents of each asc key to payload string.
      JSON_SYS_INIT_PAYLOAD="${JSON_SYS_INIT_PAYLOAD}\"$( cat ${PGP_EXPORTED_ASC_KEY_FILE} | tr -d '\n' )\"${COMMA_STR}"
    fi

    # Increment forward to the next key.
    ITER=$(($ITER + 1))
  done

  # JSON: Append our secret shares to payload string (synonymous with key-shares),
  #       and append our secret threshold to payload string (synonymous with key-threshold).
  JSON_SYS_INIT_PAYLOAD="${JSON_SYS_INIT_PAYLOAD}],\"secret_shares\":$(($n - 1)),\"secret_threshold\":$(($n - 2))}"

  # JSON: Send our payload string to the ${VAULT_ADDR}/v1/sys/init endpoint.
  curl \
    --request PUT \
    --data "${JSON_SYS_INIT_PAYLOAD}" \
    ${VAULT_ADDR}/v1/sys/init | \
    jq > /response.txt

  local SYS_INIT_KEYS_LINE=-1
  local UNSEAL_RESPONSE=
  local INITIAL_ROOT_TOKEN=

  n=0 # Reset value of 'n'.

  while IFS= read SYS_UNSEAL_LINE; do
    n=$(($n + 1))

    if [ ! -z "$( echo "${SYS_UNSEAL_LINE}" | grep -o '"keys":' )" ]; then
      # Record the line number where the 'keys' field is located.
      [ $SYS_INIT_KEYS_LINE -eq -1 ] && SYS_INIT_KEYS_LINE=$n

    elif [ ! -z "$( echo "${SYS_UNSEAL_LINE}" | grep -o '],' )" ]; then
      # Delete the line number.
      [ $SYS_INIT_KEYS_LINE -gt -1 ] && SYS_INIT_KEYS_LINE=-1

    elif [ ! -z "$( echo "${SYS_UNSEAL_LINE}" | grep -o '"root_token":' )" ]; then
      # Decrypt the initial root token.
      INITIAL_ROOT_TOKEN="$( \
        echo "${SYS_UNSEAL_LINE}" | \
        sed "s/^.*\"root_token\":.*\"\([^ ]\{4,\}\)\".*$/\1/g" | \
        base64 -d | \
        gpg \
        --pinentry-mode loopback \
        --decrypt \
        --passphrase "$( \
          sed '1q' < ${HOME}/.raw/pgp-key-1-asc-passphrase.raw | \
          tr -d '\n' \
        )" | tr -d '\n' \
      )"

    else
      if [ $SYS_INIT_KEYS_LINE -gt -1 ]; then
        # Decrypt keys.

        local UNSEAL_KEY_NUM=$(($n + 1 - $SYS_INIT_KEYS_LINE))
        if [ $UNSEAL_KEY_NUM -le $MAX_ITER ]; then
          local UNSEAL_KEY_STR="$( \
            echo "${SYS_UNSEAL_LINE}" | \
            sed "s/^.*\"\([a-f0-9]\{2,\}\)\"[,]\{0,1\}.*$/\1/g;" | \
            xxd -r -ps | \
            gpg \
            --pinentry-mode loopback \
            --decrypt \
            --passphrase "$( \
              sed '1q' < ${HOME}/.raw/pgp-key-${UNSEAL_KEY_NUM}-asc-passphrase.raw | \
              tr -d '\n' \
            )" | tr -d '\n' \
          )"
          local JSON_SYS_UNSEAL_PAYLOAD="{\"key\":\"${UNSEAL_KEY_STR}\"}"
          UNSEAL_RESPONSE="$( \
            curl \
            --request PUT \
            --data "${JSON_SYS_UNSEAL_PAYLOAD}" \
            ${VAULT_ADDR}/v1/sys/unseal | \
            tr -d '\n' \
          )"

        else
          echo -e "\033[1;31m\033[47m Number of Key Shares Exceeded! \033[0m"
        fi
      fi
      if [ ! -z "$( echo ${UNSEAL_RESPONSE} | grep -o '0,' )" ] && \
      [ ! -z "${INITIAL_ROOT_TOKEN}" ]; then
        # Display our results once Vault is unsealed and the initial root token has been decrypted.
        echo -e "\033[0;37m\033[43m$( echo "${UNSEAL_RESPONSE}" | jq )\033[0m"
        echo -e "\033[1;33m\033[40mThe Initial Root Token is:\033[0;33m\033[40m\n${INITIAL_ROOT_TOKEN}\033[0m\n"
        break

      fi
    fi
  done < response.txt
}
pgp_pkill_gpg_agent_daemon() {
  pkill gpg-agent
}