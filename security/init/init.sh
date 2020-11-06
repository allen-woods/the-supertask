#!/bin/sh

#!/bin/sh

# Work in progress!

# HashiCorp recommends maintaining root certificate outside of Vault and
# providing Vault a signed intermediate CA.
#
# Following tutorial, we:
function trust {
  # Generate a randomized 32 character salt using [:graph:]
  # character set.
  #
  # NOTE: This becomes base64 encoded with no padding.
  #
  local saltStr="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w32 | \
  head -n1)"

  # Generate a random password using [:graph:] character set
  # and length ranging from 128 to 8192 characters.
  #
  # NOTE: This becomes base64 encoded with no padding.
  #
  local passStr="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w$(jot -w %i -r 1 128 8192) | \
  head -n1)"

  # Generate the encoded hash string from Argon2.
  local encdStr=$(echo -n $passStr | argon2 $saltStr -id -t 5 -m 16 -p 4 -l 32 -e)

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