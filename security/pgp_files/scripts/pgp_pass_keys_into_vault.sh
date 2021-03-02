#!/bin/sh

# Utility function that passes *.asc files into Vault.
# Usage:
# passPGPKeysIntoVault [import_path] [key_prefix_string]
function passPGPKeysIntoVault {
  local arg1=${1:-/pgp/keys/*}
  local arg2=${2:-'key'}
  local file_ext='.asc'
  local ROOT_KEY_ASC=
  local KEYS_ASC=
  local n=0

  for asc in $arg1
  do
    n=$(($n + 1))

    if [[ "$n" -eq 1 ]] && [ -z $ROOT_KEY_ASC ]
    then
      ROOT_KEY_ASC="${asc}"
    fi

    if [[ "$n" -gt 1 ]]
    then
      if [ -z $KEYS_ASC ]
      then
        KEYS_ASC="${asc}"
      else
        KEYS_ASC="${KEYS_ASC},${asc}"
      fi
    fi
  done

  if [ $n -eq 0 ]
  then
    echo ''
    echo "CRITICAL: no data was processed!"
    echo ''
    return 1
  fi

  echoHorizontalRule --thick
  echo " * Passing PGP Keys * "
  echoHorizontalRule --thin

  [ "${VAULT_ADDR}" == "http://127.0.0.1" ] && \
  echo "   Export of VAULT_ADDR is Alive." || \
  echo " ! VAULT_ADDR Export Lost."

  echo "   Running Vault operator init."
  vault operator init \
  -key-shares=$(($n - 1)) \
  -key-threshold=$(($n - 2)) \
  -root-token-pgp-key=$ROOT_KEY_ASC \
  -pgp-keys=$KEYS_ASC
  INIT_SUCCEEDED=$?

  echoHorizontalRule --thin
  [ $INIT_SUCCEEDED -eq 0 ] && \
  echo "** Init OK! End Initialization **" || \
  echo "* * * UH-OH, something went wrong... * * *"
  echoHorizontalRule --thick
  echo ''
}