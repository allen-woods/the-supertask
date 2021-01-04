#!/bin/sh

function pgp_generate_and_run_batch {
  local BATCH_FILENAME=".$(random_string a-f0-9 16 16)"
  local PHRASE="$1"
  local n=0
  local count=0

  for c in $PHRASE
  do
    count=$(($count + 1))
  done

  for p in $PHRASE
  do
    echo ''"%echo Generating Key [$(($n + 1)) / $count]"'
    '"Key-Type: RSA"'
    '"Key-Length: 4096"'
    '"Subkey-Type: RSA"'
    '"Subkey-Length: 4096"'
    '"Passphrase: $p"'
    '"Name-Real: Thomas Tester"'
    '"Name-Email: thomas@testing.com"'
    '"Name-Comment: This is an automated test key."'
    '"Expire-Date: 0"'
    ' >> $BATCH_FILENAME

    n=$(($n + 1))
  done

  echo '
  '"%commit"'
  '"%echo Done!"'' >> $BATCH_FILENAME

  chown root:root $BATCH_FILENAME
  chmod 0400 $BATCH_FILENAME
  
  gpg2 \
  --verbose \
  --batch \
  --gen-key $BATCH_FILENAME

  rm $BATCH_FILENAME
}