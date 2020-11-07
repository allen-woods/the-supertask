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
  # Generate the encoded hash string from Argon2. (KEK is at end of string)
  # Length of 60 uses 384 bits of entropy.
  local kek=$(echo -n $passStr | argon2 $saltStr -id -t 5 -m 16 -p 4 -l 60 -e)

  echo "Generating encryption data (1/1)..."
  local fek="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w$(jot -w %i -r 1 20 35) | \
  head -n1)"
  
  fek_encd="$( \
  openssl enc 
  )"
  # Generate FEK
  # Encrypt FEK into FEK* using passStr and encdStr
  # Store 
  # Generate directory structure for our secure files.
  #
  # NOTE: add strict chmod and chown settings
  #
  mkdir -p $HOME/tls/certs
  mkdir -p $HOME/tls/private

  # Move current directory to $HOME.
  cd $HOME

  # Store password in `phrase.raw` file inside root directory.
  echo $passStr > phrase.raw

  # Store encoded hash from Argon2 inside `phrase.enc` file.
  echo $encdStr > ./tls/certs/phrase.enc
}