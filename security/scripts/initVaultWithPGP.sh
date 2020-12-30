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

  # Initialize Vault to use the support files.
  passPGPKeysIntoVault
}