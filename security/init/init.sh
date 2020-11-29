#!/bin/sh

# 1. Generate Passphrases.
# 2. Generate shell script containing Passphrases.
# 3. Generate Keys.
# 4. Copy keys into Vault
# 5. Pass exported keys into Vault init.

# Utility function for turning ints into unsigned ints.
# Usage:
# int_uint integer
function int_uint {
  if [ -z $1 ]
  then
    echo "int_uint: must provide number as argument"
    exit 1
  elif [ $1 -lt 0 ]
  then
    echo $(($1 * -1))
  else
    echo $1
  fi
}

# Utility function for generating random strings.
# Usage:
# random_string [regex_pattern] [min_length] [max_length]
function random_string {
  local arg1=${1:-a-f0-9}
  local arg2=
  local arg3=

  if [ ! -z $2 ] && [ ! -z $3 ]
  then
    if [ $(int_uint $3) -lt $(int_uint $2) ]
    then
      arg2=$(int_uint ${3:-40})
      arg3=$(int_uint ${2:-99})
    else
      arg2=$(int_uint ${2:-40})
      arg3=$(int_uint ${3:-99})
    fi
    if [ $arg2 -eq $arg3 ]
    then
      echo $( \
      tr -cd $arg1 < /dev/urandom | \
      fold -w$arg2 | \
      head -n1 \
      )
    else
      echo $( \
      tr -cd $arg1 < /dev/urandom | \
      fold -w$(jot -w %i -r 1 $arg2 $arg3) | \
      head -n1 \
      )
    fi
  fi
}

# Utility function for parsing end exporting generated keys.
# Usage:
# export_keys [revoc_path] [export_path] [prefix_string]
function export_keys {
  local arg1=${1:-${HOME}/.gnupg/openpgp-revocs.d/*}
  local arg2=${2:-${HOME}/.gnupg}
  local arg3=${3:-'key'}
  local n=1

  cd $arg2
  mkdir -m 0600 ./enc
  chown root:root ./enc

  for file in $arg1
  do
    echo "Exporting: $arg3 $n"
    gpg2 \
    --export \
    "$(basename "$file" | cut -f 1 -d '.')" | \
    base64 > "/encoded/keys/$arg3$n.asc"
    $n=$(($n + 1))
  done
}

# Utility function for generating random passphrases.
# Usage:
# generate_passphrases [phrase_count] [regex_pattern]
function generate_passphrases {
  local arg1=$(int_uint ${1:-4})
  local arg2=${2:-[:alnum:][:punct:]}
  local n=0
  local PHRASE=""

  while [ $n -lt $arg1 ]
  do
    if [ PHRASE = "" ]
    then
      PHRASE="$(random_string $arg2)"
    else
      PHRASE="$PHRASE $(random_string $arg2)"
    fi
    $n=$(($n + 1))
  done
  echo $PHRASE
}

# Utility function for encrypting passphrases to an output file.
# Usage:
# encrypt_passphrases <passphrase_string> [prefix_string] [export_path]
function encrypt_passphrases {
  if [ -z $1 ]
  then
    echo "encrypt_passphrases: must pass string of space-delimited passphrases as argument"
    exit 1
  fi

  local arg2=${2:-'key'}
  local arg3=${3:-/encoded/phrases}
  local file_ext='.asc'
  local plaintext=""
  local n=1

  cd $arg3

  for phrase in $1
  do
    if [ plaintext = "" ]
      plaintext="$arg2$n$file_ext:$phrase"
    else
      plaintext="$plaintext $arg2$n$file_ext:$phrase"
    fi
    $n=$(($n + 1))
  done

  local PARAM_K=00000000000000000000000000000000
  local PARAM_IV=00000000000000000000000000000000

  openssl \
  aes-256-cbc \
  -a \
  -K $PARAM_K \
  -iv $PARAM_IV \
  -in <(echo "$($plaintext | tr ' ' '\n')") \
  -out keyphrase.enc
}

# Utility function that passes *.asc files into Vault.
# Usage:
# pass_keys_into_vault [import_path] [key_prefix_string]
function pass_keys_into_vault {
  local arg1=${1:-/encoded/keys}
  local arg2=${2:-'key'}
  local file_ext='.asc'
  local ROOT_KEY_ASC=
  local KEYS_ASC=""
  local n=0

  for asc in $arg1
    $n=$(($n + 1))

    if [ $n -eq 1 ]
    then
      ROOT_KEY_ASC="$asc"
    else
      if [ $KEYS_ASC = "" ]
        KEYS_ASC="\"$asc\""
      else
        KEYS_ASC="$KEYS_ASC,\"$asc\""
      fi
    fi
  do

  local api_v1="http://127.0.0.1:8200/v1"
  local sys_init_addr=$api_v1/sys/init
  local json_data "\{\"root_token_pgp_key\":\"$ROOT_KEY_ASC\",\"pgp_keys\":\[$(echo $KEYS_ASC | tr ',' ',\n')\],\"secret_shares\":$(($n - 1)),\"secret_threshold\":$(($n - 2))\}"

  echo "** Begin Initialization **"

  curl \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -X PUT \
  -d $json_data \
  $sys_init_addr | jq

  local response=false

  echo "Verifying initialization..."
  while [ "$(echo -n $response | grep -w false)" = "false" ]; do
    response=$(curl \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -X GET \
    $sys_init_addr)
  done

  echo "** Init OK! End Initialization **"
  echo $response | jq
}

function generate_and_run_batch {
  local BATCH_FILENAME=".$(random_string a-f0-9 16 16)"
  local arg1=$(int_uint ${1:-4})
  local PHRASE=$(generate_passphrases $arg1)
  local n=0

  for p in $PHRASE
  do
    echo ''"%echo Generating Key [$(($n + 1)) / $1]"'
    '"Key-Type: RSA"'
    '"Key-Length: 4096"'
    '"Subkey-Type: RSA"'
    '"Subkey-Length: 4096"'
    '"Passphrase: $p"'
    '"Name-Real: "'
    '"Name-Email: "'
    '"Name-Comment: "'
    '"Expire-Date: 0"'
    ' >> $BATCH_FILENAME

    $n=$(($n + 1))
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

function init_vault_with_pgp {
  generate_and_run_batch

}

function init_vault {
  cd ${HOME}/.gnupg

  # local min=[ $3 -lt $2 ] && $3 || $2
  # local max=[ $2 -gt $3 ] && $2 || $3


  local BATCH_FILENAME=".$(random_string a-f0-9 16 16)"
  local arg1=${1:-4}
  local PHRASE=""
  local n=0

  while [ $n -lt ${1:-4} ]
  do
    if [ PHRASE = "" ]
    then
      PHRASE="$(random_string)"
    else
      PHRASE="$PHRASE $(random_string)"
    fi

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
      ' >> $BATCH_FILENAME

    $n=$(($n + 1))
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