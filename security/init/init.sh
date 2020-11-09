#!/bin/sh

# Work in progress!

# HashiCorp recommends maintaining root certificate outside of Vault and
# providing Vault a signed intermediate CA.
#
# Following tutorial, we:
function trust {
  echo "Checking for maximum entropy (This might take a while)..."
  maxEntropy=0
  while [ ! $maxEntropy -eq 4096 ]; do
    #
    # Do stuff here that generates entropy.
    #

    # Update max entropy available.
    maxEntropy=$(cat /proc/sys/kernel/random/entropy_avail);
  done
  echo "Maximum entropy reached!"

  # Entropy information:
  # https://advancedweb.hu/what-is-the-optimal-password-length/

  echo "Generating salt..."
  # Generate a randomized 35 character salt using [:graph:]
  # character set. ([:alnum:][:punct:])
  #
  # This will mandate 224 bits of entropy for all generated salt.
  #
  # NOTE: This becomes base64 encoded with no padding.
  #
  local saltStr="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w35 | \
  head -n1)"

  echo "Generating STRONG random password..."
  # Generate a random password using [:graph:] character set
  # and length ranging from 20 to 35 characters.
  #
  # This will yield between 128 bits and 224 bits of entropy;
  # the upper limit being double the minimum government standard.
  #
  # NOTE: This also becomes base64 encoded with no padding.
  #
  local passStr="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w$(jot -w %i -r 1 20 35) | \
  head -n1)"

  echo '
  ** IMPORTANT: ********************************************
  ** Your secure STRONG password has been generated.      **
  **                                                      **
  ** THIS VALUE WILL NOT BE SAVED OR PERSISTED!           **
  ** PLEASE WRITE THIS VALUE DOWN AND SAFEGUARD THE DATA. **
  **                                                      **
  ** Your secure STRONG password is as follows:           **
  **********************************************************

  '"$passStr"'

  '

  echo "Hashing password..."
  # Generate the encoded hash string from Argon2.
  # Length of 60 uses 384 bits of entropy.
  local kek=$(echo -n $passStr | argon2 $saltStr -id -t 5 -m 16 -p 4 -l 60 -e)

  echo "Generating encryption data (1/1)..."
  local fek="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w$(jot -w %i -r 1 20 35) | \
  head -n1)"

  # Parse the salt and hash from kek, convert both to hex, assign to vars.
  if [[ $kek =~ ^p=4\$(.*)\$(.*)$ ]]; then
    local kekSalt="$( \
    echo 0: ${BASH_REMATCH[1]} | xxd -r | \
    openssl enc -aes-256-ecb -nopad -K 00000000000000000000000000000000 | \
    xxd -p)"

    local kekHash="$( \
    echo 0: ${BASH_REMATCH[2]} | xxd -r | \
    openssl enc -aes-256-ecb -nopad -K 00000000000000000000000000000000 | \
    xxd -p)"
  fi
  
  # Encode FEK into FEK* using kekHash and kekSalt.
  # FEK* is persisted as fek.enc
  openssl enc -aes-256-ecb -in fek -out fek.enc \
  -e -K $kekHash -S $kekSalt
  
  # Enforce tight restrictions on fek.enc, root user only.
  chown root:root fek.enc
  chmod 0600 fek.enc

  # Generate directory structure for our secure files.
  mkdir -m 0600 -p $HOME/tls/certs
  mkdir -m 0600 -p $HOME/tls/private

  # Move current directory to $HOME.
  cd $HOME

  # Store password in `phrase.raw` file inside root directory.
  echo $passStr > phrase.raw

  # Store encoded hash from Argon2 inside `phrase.enc` file.
  echo $encdStr > ./tls/certs/phrase.enc
}