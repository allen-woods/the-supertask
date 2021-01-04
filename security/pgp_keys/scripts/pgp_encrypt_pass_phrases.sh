#!/bin/sh

# Utility function for encrypting passphrases to an output file.
# Usage:
# encryptPassPhrases <passphrase_string> [prefix_string] [export_path]
function pgp_encrypt_pass_phrases {
  local arg1="$1"
  if [ ! -z arg1 ]
  then
    local arg2=${2:-'key'}
    local arg3=${3:-/pgp/phrases}
    local file_ext='.asc'
    local plaintext=
    local n=1

    cd $arg3

    for phrase in $arg1
    do
      if [ -z plaintext ]
      then
        plaintext="${arg2}${n}${file_ext}${phrase}"
      else
        plaintext="${plaintext} ${arg2}${n}${file_ext}${phrase}"
      fi
      n=$(($n + 1))
    done

    # Length of 64 recommended.
    # local PARAM_K=0000000000000000000000000000000000000000000000000000000000000000
    
    # Length of 32 recommended.
    # local PARAM_IV=00000000000000000000000000000000

    echo $(echo -n "$plaintext" | \
    tr ' ' '\n' | \
    openssl \
    aes-256-cbc \
    -e \
    -a \
    -K $(pipe_read "name_of_pipe" 1 --no-delete) \
    -iv $(pipe_read "name_of_pipe" 2 --delete-all) \
    -iter 20000 \
    -pbkdf2 \
    ) >> keyphrase.enc
  fi
}