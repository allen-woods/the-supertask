#!/bin/sh

vault_operator_init_pgp_key_shares() {
  local PUB_PATH=/pgp/keys/pub
  #local IMPORT_PATH=$HOME/.gnupg/private-keys-v1.d
  local ROOT_KEY_ASC=
  local KEYS_ASC=
  local n=0

  chown root:root $HOME/.gnupg
  apk --no-cache add gnupg pinentry-gtk

  for ASC in $PUB_PATH/*; do
    n=$(($n + 1))
    if [ $n -eq 1 ]; then
      [ -z "${ROOT_KEY_ASC}" ] && ROOT_KEY_ASC="${ASC}"
    elif [ $n -gt 1 ]; then
      [ -z "${KEYS_ASC}" ] && KEYS_ASC="${ASC}" || KEYS_ASC="${KEYS_ASC},${ASC}"
    fi
  done

  [ $n -eq 0 ] && echo -e "\033[7;31mFATAL ERROR: No data was processed!\033[0m" && return 1

  # Check for the presence of the required env var VAULT_ADDR.
  [ -z "$(echo ${VAULT_ADDR} | grep -o http://127.0.0.1)" ] && \
  pretty "VAULT_ADDR not Exported" --error && return 1 ||
  pretty "Export of VAULT_ADDR Confirmed"

  # The path where the welcome message will be stored.
  local EXPORT_PATH=/to_host/vault
  
  # The file where the welcome message will be persisted.
  local EXPORT_FILE=".$(tr -cd \_a-z-A-Z0-9 < /dev/random | fold -w32 | head -n1)"
  
  # Conditionally generate the path only when needed.
  [ ! -d $EXPORT_PATH ] && mkdir -p $EXPORT_PATH

  # Initialize Vault to use PGP hardening of its data-at-rest.
  # Send the resulting welcome message to the export file within the export path.
  echo "$( \
    vault operator init \
    -key-shares=$((n - 1)) \
    -key-threshold=$((n - 2)) \
    -root-token-pgp-key=$ROOT_KEY_ASC \
    -pgp-keys=$KEYS_ASC \
  )" > "${EXPORT_PATH}/.${EXPORT_FILE}"
  [ $? -gt 0 ] && \
  pretty "SOMETHING NOPED..." --error && return 1 || \
  pretty "SUCCESS!!"
}