#!/bin/sh

# This function generates all data needed to init
# Vault with PGP keys. It is intended to be used
# with a "builder" stage container.
generatePGPData() {
  local arg1=$(abs ${1:-4})
  local phrases=$(generatePassPhrases $arg1)

  echoHorizontalRule --thick
  echo " * Checking for Existing PGP Data * "
  echoHorizontalRule --thin

  echo "   Including hidden files in search."

  echo "   Checking for Existing Keys."
  existingKeys="$(echo $(ls -A /pgp/keys 2>/dev/null))"

  echo "   Checking for Existing Phrases."
  existingPhrases="$(echo $(ls -A /pgp/phrases 2>/dev/null))"

  local checkMessage=" * PASSED: No Existing PGP Data Found * "
  local cancelGenerate=0
  
  if [ ${#existingKeys} -gt 0 ] && [ ${#existingPhrases} -gt 0 ]
  then
    checkMessage=" * SKIPPING: PGP Data Already Created"
    cancelGenerate=1
  fi

  echoHorizontalRule --thin
  echo "${checkMessage}"
  echoHorizontalRule --thick
  echo ''
  
  if [ $cancelGenerate -eq 1 ]
  then
    # Silently create dirs to prevent broken build.
    ( mkdir -p /pgp/keys ) > /dev/null 2>&1
    ( mkdir /pgp/phrases ) > /dev/null 2>&1
  else
    echoHorizontalRule --thick
    echo " * Begin PGP Data Generation * "
    echoHorizontalRule --thin

    echo "   Creating Directory for Keys."
    mkdir -p /pgp/keys

    echo "   Creating Directory for Phrases."
    mkdir /pgp/phrases
    
    # Give feedback to the user that build isn't hanging.
    echo "   Generating Batch File."

    echo "   Running Batch File..."
    ( generateAndRunPGPBatch "$phrases" ) > /dev/null 2>&1
    
    echo "   Exporting Keys."
    ( exportPGPKeys ) > /dev/null 2>&1
    
    echo "   Exporting Phrases."
    ( encryptPassPhrases "$phrases" ) > /dev/null 2>&1

    echoHorizontalRule --thin
    echo " * COMPLETE: All PGP Data Generated. * "
    echoHorizontalRule --thick
    echo ''
  fi
}