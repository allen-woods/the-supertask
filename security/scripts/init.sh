#!/bin/sh

# Utility function for turning ints into unsigned ints (positive only).
# Usage:
# int_uint <integer>
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
  fi

  if [ -z $arg2 ] || [ -z $arg3 ]
  then
    arg2=40
    arg3=99
  fi

  if [[ $arg2 -eq $arg3 ]]
  then
    echo -n $( \
    tr -cd $arg1 < /dev/urandom | \
    fold -w$arg2 | \
    head -n1 \
    )
  else
    echo -n $( \
    tr -cd $arg1 < /dev/urandom | \
    fold -w$(jot -w %i -r 1 $arg2 $arg3) | \
    head -n1 \
    )
  fi
}

# Utility function for parsing end exporting generated keys.
# Usage:
# export_keys [revoc_path] [export_path] [prefix_string]
function export_keys {
  local arg1=${1:-${HOME}/.gnupg/openpgp-revocs.d/*}
  local arg2=${2:-/encoded/keys}
  local arg3=${3:-'key'}
  local n=1

  cd $arg2
  
  for file in $arg1
  do
    echo "Exporting: $arg3 $n"

    gpg2 \
    --export \
    "$(basename "$file" | cut -f 1 -d '.')" | \
    base64 > "$arg2/$arg3$n.asc"

    n=$(($n + 1))
  done
}

# Utility function for generating random passphrases.
# Usage:
# generate_passphrases [phrase_count] [regex_pattern]
function generate_passphrases {
  local arg1=$(int_uint ${1:-4})
  local arg2=${2:-_A-Z-a-z0-9~!@#%^&*()=+[]|;:,<.>?}
  local n=0
  local PHRASE=

  while [ $n -lt $arg1 ]
  do
    if [ -z PHRASE ]
    then
      PHRASE="$(random_string $arg2)"
    else
      PHRASE="$PHRASE $(random_string $arg2)"
    fi
    n=$(($n + 1))
  done
  echo -n $PHRASE
}

# Utility function for encrypting passphrases to an output file.
# Usage:
# encrypt_passphrases <passphrase_string> [prefix_string] [export_path]
function encrypt_passphrases {
  local arg1="$1"
  if [ "$arg1" = "" ]
  then
    echo "encrypt_passphrases: must pass string of space-delimited passphrases as argument"
    exit 1
  fi

  local arg2=${2:-'key'}
  local arg3=${3:-/encoded/phrases}
  local file_ext='.asc'
  local plaintext=
  local n=1

  cd $arg3

  for phrase in $arg1
  do
    if [ "$plaintext" = "" ]
    then
      plaintext="$arg2"''"$n"''"$file_ext"':'"$phrase"
    else
      plaintext="$plaintext"' '"$arg2"''"$n"''"$file_ext"':'"$phrase"
    fi
    n=$(($n + 1))
  done

  # Must have length of 64
  local PARAM_K=0000000000000000000000000000000000000000000000000000000000000000
  
  # Must have length of 32
  local PARAM_IV=00000000000000000000000000000000

  echo $(echo -n "$plaintext" | \
  tr ' ' '\n' | \
  openssl \
  aes-256-cbc \
  -e \
  -a \
  -K $PARAM_K \
  -iv $PARAM_IV \
  -iter 20000 \
  -pbkdf2 \
  ) >> keyphrase.enc
}

# Utility function that passes *.asc files into Vault.
# Usage:
# pass_keys_into_vault [import_path] [key_prefix_string]
function pass_keys_into_vault {
  local arg1=${1:-/encoded/keys/*}
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
      ROOT_KEY_ASC="$asc"
    fi

    if [[ "$n" -gt 1 ]]
    then
      if [ -z $KEYS_ASC ]
      then
        KEYS_ASC="$asc"
      else
        KEYS_ASC="$KEYS_ASC,$asc"
      fi
    fi
  done

  echo "** Begin Initialization **"

  export VAULT_ADDR="http://127.0.0.1:8200"

  vault operator init \
  -key-shares=$(($n - 1)) \
  -key-threshold=$(($n - 2)) \
  -root-token-pgp-key="$ROOT_KEY_ASC" \
  -pgp-keys="$KEYS_ASC"

  echo "** Init OK! End Initialization **"
}

function generate_and_run_batch {
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

function init_vault_with_pgp {
  local arg1=$(int_uint ${1:-4})
  local phrases=$(generate_passphrases $arg1)

  generate_and_run_batch "$phrases"
  export_keys
  encrypt_passphrases "$phrases"
  pass_keys_into_vault
}