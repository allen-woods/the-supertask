#!/bin/sh

# This function generates all data needed to init
# Vault with PGP keys. It is intended to be used
# with a "builder" stage container.
generatePGPData() {
  local arg1=$(abs ${1:-4})
  local phrases=$(generatePassPhrases $arg1)

  echo "Building directory structure."
  ( mkdir -p /pgp/keys ) > /dev/null 2>&1
  ( mkdir /pgp/phrases ) > /dev/null 2>&1
  
  # Give feedback to the user that build isn't hanging.
  echo "Please wait, sensitive data is being generated..."

  echo " - Batch file"
  ( generateAndRunPGPBatch "$phrases" ) > /dev/null 2>&1
  
  echo " - Export Data 1"
  ( exportPGPKeys ) > /dev/null 2>&1
  
  echo " - Export Data 2"
  ( encryptPassPhrases "$phrases" ) > /dev/null 2>&1

  echo "OK!"
}