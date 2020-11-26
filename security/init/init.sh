#!/bin/sh

function init_vault {
  # Extended params:
  #   "pgp_keys": [
  #     "file1.asc",
  #     "file2.asc",
  #     "file3.asc"
  #   ],
  #   "root_token_pgp_key": "fileX.asc",

  # Stop on first error.
  set -e

  # Generate `.gnupg` directory in ${HOME}.
  gpg2 --list-keys

  # Set current directory to `.gnupg` in ${HOME}.
  cd ${HOME}/.gnupg

  # Use multi-line string literal (POSIX doesn't support heredoc).
  echo '
  '"%echo Generating a basic OpenPGP key"'
  '"Key-Type: RSA"'
  '"Key-Length: 4096"'
  '"Subkey-Type: RSA"'
  '"Subkey-Length: 4096"'
  '"Name-Real: Some Name"'
  '"Name-Comment: Some Name"'
  '"Name-Email: somename@site.com"'
  '"Expire-Date: 0"'
  '"%no-ask-passphrase"'
  '"%no-protection"'
  '"%pubring pubring.kbx"'
  '"%secring trustdb.gpg"'
  '"%commit"'
  '"%echo done"'
  ' > keydetails

  # Generate the key using automated details.
  gpg2 --verbose --batch --gen-key keydetails

  # Set trust to 5 to prevent prompt during encrypt.
  echo -e "5\ny\n" | gpg2 --command-fd 0 --expert --edit-key somename@site.com trust;
  
  # Test to confirm creation and permission level of key.
  gpg2 --list-keys

  # Test to confirm encrypt / decrypt capabilities of key.
  gpg2 -e -a -r somename@site.com keydetails

  # Delete temporary files.
  rm keydetails
  # Send decrypted original to stdout.
  gpg2 -d keydetails.asc
  rm keydetails.asc

  local api_v1="http://127.0.0.1:8200/v1"
  local sys_init=/usr/local/init/sys_init.json
  local sys_init_addr=$api_v1/sys/init

  echo "** Begin Initialization **"

  curl \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -X PUT \
  -d @$sys_init \
  $sys_init_addr | jq

  local res=false

  echo "Verifying initialization..."
  while [ "$(echo -n $res | grep -w false)" = "false" ]; do
    res=$(curl \
    -s
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -X GET \
    $sys_init_addr)
  done

  echo "** Init OK! **"
  echo "$res" | jq
}