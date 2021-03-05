#!/bin/sh

function initVaultWithPGP {
  if [ "$(pwd)" != "/" ]
  then
    cd /
  fi

  if [ ! -d "/pgp" ]
  then
    mkdir pgp
  fi
  
  # Move all support files into their proper places.
  if [ -d "/keys" ] && [ ! -d "/pgp/keys" ]
  then
    mv /keys /pgp/keys
  fi

  if [ -d "/phrases" ] && [ ! -d "/pgp/phrases" ]
  then
    mv /phrases /pgp/phrases
  fi

  if [ ! -d "/pgp/keys" ] && [ ! -d "/pgp/phrases" ]
  then
    echo "* * ERROR: No PGP Data Found! * *"
    return 1
  fi

  echo "* * * * * * * * * *"
  echo "RUNNING SCRIPTS AS: $(whoami)"
  echo "* * * * * * * * * *"
  echo "PROCESSES:"
  echo "$(ps)"

  echoHorizontalRule --thick
  echo " * Begin Vault Init Process * "
  echoHorizontalRule --thin

  export VAULT_ADDR="http://127.0.0.1:8200"
  
  [ "${VAULT_ADDR}" == "http://127.0.0.1" ] && \
  echo "   Export of VAULT_ADDR Confirmed." || \
  echo " ! VAULT_ADDR Failed to Export."

  echo "   Starting Vault Server as Background Process."
  # Start server with proper config file.
  (
    vault server \
    -config=/vault/config \
    -dev-root-token-id= \
    -dev-listen-address=0.0.0.0:8200
  ) &

  echoHorizontalRule --thin
  echo " * COMPLETED: Vault Server is Running. *"
  echoHorizontalRule --thick
  echo ''

  # Initialize Vault to use the support files.
  passPGPKeysIntoVault
}