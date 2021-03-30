#!/bin/sh

vault_v1_pki_config_ca_submit_ca_information() {
  local PEM_PATH=/tls/intermediate/certs
  local PEM_FILE=ca-chain-bundle.cert.pem
  local TOKEN_PATH=/to_host/vault
  local TOKEN_FILE=

  # Not able to find the PEM path is a fatal error.
  [ ! -d $PEM_PATH ] && pretty "PEM path not found!" --error && return 1
  # Not able to find the PEM file is a fatal error.
  [ ! -f "${PEM_PATH}/${PEM_FILE}" ] && pretty "PEM file not found!" --error && return 1
  # Not able to find the token path is a fatal error.
  [ ! -d $TOKEN_PATH ] && pretty "Token path not found!" --error && return 1

  for FILE in $TOKEN_PATH/.*; do
    local TMP_FILE="$(basename ${FILE})"

    [ ${#TMP_FILE} -gt 2 ] && \
    [ -z $TOKEN_FILE ] && TOKEN_FILE="${TMP_FILE}" && break
  done

  # Not able to find the token file is a fatal error.
  [ -z $TOKEN_FILE ] && pretty "Token file not found!" --error && return 1

  gpg-agent --daemon --pinentry-program pinentry-gtk # DEBUG
  
  ps # DEBUG

  local PARSED_PEM_BUNDLE="$(cat "${PEM_PATH}/${PEM_FILE}" | tr '\n' '\t' | sed 's/\t/\\n/g')"
  printf '%s\n' "{" "  \"pem_bundle\": \"${PARSED_PEM_BUNDLE}\"" "}" > /vault/config/v1_pki_config_ca_payload.json

  local UNSEAL_1=$(cat "${TOKEN_PATH}/${TOKEN_FILE}" | sed '1q;d' | sed 's/ //g' | cut -f2 -d ':')
  printf '%s\n' "{" "  \"key\": \"${UNSEAL_1}\"" "}" > /vault/config/v1_sys_unseal_1_payload.json

  local UNSEAL_2=$(cat "${TOKEN_PATH}/${TOKEN_FILE}" | sed '2q;d' | sed 's/ //g' | cut -f2 -d ':')
  printf '%s\n' "{" "  \"key\": \"${UNSEAL_2}\"" "}" > /vault/config/v1_sys_unseal_2_payload.json
  
  local PARSED_ROOT_TOKEN=$(cat "${TOKEN_PATH}/${TOKEN_FILE}" | tr -d '\n' | sed 's/^.*Initial Root Token: \([^ ]\{1,\}\).*$/\1/g')

  apk --no-cache add curl

  pretty "Attempting to Decode Unseal 1 Using \"pinentry-gtk\"..."
  echo $( \
    echo "not_the_right_password" | \
    gpg --verbose \
    --batch \
    --pinentry-mode loopback \
    --decrypt "$( \
      ${UNSEAL_1} | \
      base64 -d \
    )" \
  )
  
  pkill gpg-agent
  
  # Pass unseal key 1 to Vault.
  local CURL_RESPONSE="$( \
    curl \
    --request PUT \
    --data @/vault/config/v1_sys_unseal_1_payload.json \
    "${VAULT_ADDR}/v1/sys/unseal" \
  )"
  echo $CURL_RESPONSE

  # Pass unseal key 2 to Vault.
  curl \
  --request PUT \
  --data @/vault/config/v1_sys_unseal_2_payload.json \
  "${VAULT_ADDR}/v1/sys/unseal"
  # Pass TLS certificate chain bundle to Vault.
  curl \
  --header "X-Vault-Token: ${PARSED_ROOT_TOKEN}" \
  --request POST \
  --data @/vault/config/v1_pki_config_ca_payload.json \
  "${VAULT_ADDR}/v1/pki/config/ca"
}