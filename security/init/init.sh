#!/bin/sh

# 1. Generate Passphrases.
# 2. Generate shell script containing Passphrases.
# 3. Generate Keys.
# 4. Copy keys into Vault
# 5. Pass exported keys into Vault init.
# Utility function for generating random strings.
function random_string {
  if [ ! -z $2] && [ ! -z $3 ]
  then
    if [ $2 -eq $3 ]
    then
      echo $( \
      tr -cd ${1:-a-f0-9} < /dev/urandom | \
      fold -w$2 | \
      head -n1 \
      )
    fi
  fi
  echo $( \
  tr -cd ${1:-a-f0-9} < /dev/urandom | \
  fold -w$(jot -w %i -r 1 ${2:-40} ${3:-99}) | \
  head -n1 \
  )
}

# Utility function for parsing end exporting generated keys.
function export_keys {
  local n=1
  cd ${2:-${HOME}/.gnupg}

  for file in ${1:-/root/.gnupg/openpgp-revocs.d/*}
  do
    echo "Exporting: key $n"
    
    gpg2 \
    --export \
    "$(basename "$file" | cut -f 1 -d '.')" | \
    base64 > "key$n.asc"

    $n=$(($n + 1))
  done
}

function init_vault {
  cd ${HOME}/.gnupg

  # local min=[ $3 -lt $2 ] && $3 || $2
  # local max=[ $2 -gt $3 ] && $2 || $3

  
  local BATCH_FILENAME='.'"$(rand_fmt a-f0-9 16 16)"''
  local n=0

  while [ $n -lt ${1:-4} ]
  do
      PHRASE[$n]="$(rand_fmt [:alnum:][:punct:])"

      echo ''"%echo Generating Key [$(($n + 1)) / $1]"'
      '"Key-Type: RSA"'
      '"Key-Length: 4096"'
      '"Subkey-Type: RSA"'
      '"Subkey-Length: 4096"'
      '"Passphrase: $PHRASE[$n]"'
      '"Name-Real: "'
      '"Name-Email: "'
      '"Name-Comment: "'
      '"Expire-Date: 0"'
      '"%commit"'' >> ${BATCH_FILENAME}

    $n=$(($n + 1))
  done

  echo "%echo Done." >> ${BATCH_FILENAME}
  
  gpg2 \
  --verbose \
  --batch \
  --gen-key ${BATCH_FILENAME}

  # This is how to get the hex of each key:
  # for file in /root/.gnupg/openpgp-revocs.d/*; do echo "$(basename "$file" | cut -f 1 -d '.')"; done
  
  # This is how to append to a string:
  # str="$str $new_word"

  # This is how to parse each word value of hex within appended string:
  # my_blank_str="these are some words to echo out in my loop"
  # for w in $my_blank_str; do echo "$w"; done

  # echo -e "5\ny\n" | gpg2 --command-fd 0 --expert --edit-key somename@site.com trust;
  
  # We capture the output so we can capture the hex strings for export command.
  local gpg_out=$(gpg2 --list-keys)
  
  # gpg2 -e -a -r somename@site.com ${BATCH_FILENAME}

  # First, we must parse HEXCODE from `gpg_out`.
  # gpg --export HEXCODE | base64 > file_name.asc

  echo '
  *************************
  ** Secure Passphrase List
  *************************

  '"IMPORTANT!"'
  '"These passphrases will not be persisted."'
  '"Please keep secure copies for later use."'
  '"Provide them to GPG2's prompt manually."'
  '

  $n=0

  while [ $n -lt ${1:-4} ]
  do
    echo "$n: $PHRASE[$n]"
  done

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
  '"Expire-Date: 1y"'
  '"%no-ask-passphrase"'
  '"%no-protection"'
  '"%pubring pubring.kbx"'
  '"%secring trustdb.gpg"'
  '"%commit"'
  '"%echo done"'
  ' > ${BATCH_FILENAME}

  

  # Set trust to 5 to prevent prompt during encrypt.
  echo -e "5\ny\n" | gpg2 --command-fd 0 --expert --edit-key somename@site.com trust;
  
  # Test to confirm creation and permission level of key.
  gpg2 --list-keys

  # Test to confirm encrypt / decrypt capabilities of key.
  gpg2 -e -a -r somename@site.com ${BATCH_FILENAME}

  # Delete temporary files.
  rm keydetails
  
  # Send decrypted original to stdout.
  gpg2 -d keydetails.asc
  rm keydetails.asc

  mkdir -m 0700 /usr/local/etc
  chown root:root /usr/local/etc

  echo ''"{"'
  '"\"root_token_pgp_key\": \"${ROOT_KEY_ASC}\","'
  '"\"pgp_keys\": ["'
  '"  \"${KEY_1_ASC}\","'
  '"  \"${KEY_2_ASC}\","'
  '"  \"${KEY_3_ASC}\""'
  '"],"'
  '"\"secret_shares\": 3,"'
  '"\"secret_threshold\": 2"'
  '"}"'
  ' >> /usr/local/etc/sys_init.json

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
  echo $res | jq
}