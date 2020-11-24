#!/bin/sh

# Work in progress!

# HashiCorp recommends maintaining root certificate outside of Vault and
# providing Vault a signed intermediate CA.
#
# To do this, we (mostly):
# 1. Use OpenSSL to generate symmetric key pair.
# 2. Wrap key using -id-aes256-wrap-pad.
# 3. Use keys to generate root certificate.
# 4. Self-sign the root certificate.
# 5. Generate the intermediate certificate.
function trust {
  # It is not required to increase available entropy to the maximum (4096)
  # before using `/dev/urandom`.
  #
  # For more detail: "How can I increase /proc/sys/kernel/random/entropy_avail"
  # (URL) https://security.stackexchange.com/questions/204372/how-can-i-increase-proc-sys-kernel-random-entropy-avail

  local entropyNow=$(cat /proc/sys/kernel/random/entropy_avail)
  local entropyMax=$(cat /proc/sys/kernel/random/poolsize)

  echo '
  *****************************
  '"** Starting \`Trust\` Utility"'
  **
  '"** Entropy: ${entropyNow} of ${entropyMax}"'
  *****************************
  '
  # Generate a random password
  # Echo the password to a file
  # Pass the file into a new encrypted file
  # Generate a random 32 byte aes "payload"
  # Generate a random 32 byte aes "ephemeral"
  # Generate a private RSA key that is 4096
  # Generate a public key from private key in PEM
  # Get raw hex from "ephemeral" aes.
  # Encode "payload" aes 

  # Password Entropy Information:
  # https://advancedweb.hu/what-is-the-optimal-password-length/

  echo "** Generating:"
  echo " - Payload AES"
  local payload_aes="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w32 | \
  head -n1)"

  echo " - Ephemeral AES"
  local ephemeral_aes="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w32 | \
  head -n1)"

  echo " - Private Key"
  openssl genrsa -out private.pem 4096

  echo " - Public Key"
  openssl rsa -in private.pem -out public.pem -pubout -outform PEM
  
  echo "** Extracting Hex."
  EPHEMERAL_AES_HEX=$(hexdump -v -e '/1 "%02X"' < ephemeral_aes)
  
  echo "** Wrapping:"
  echo " - Payload AES"
  openssl enc -id-aes256-wrap-pad -K $EPHEMERAL_AES_HEX -iv A65959A6 -in payload_aes -out payload_wrapped
  
  echo " - Ephemeral AES"
  openssl pkeyutl -encrypt -in ephemeral_aes -out ephemeral_wrapped -pubin -inkey public.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha1 -pkeyopt rsa_mgf1_md:sha1

  echo "** Concatenating RSA AES Wrapped"
  cat ephemeral_wrapped payload_wrapped > rsa_aes_wrapped
  
  echo "Generating STRONG random password..."
  # Generate a random password using [:graph:] character set
  # and length ranging from 20 to 35 characters.
  #
  # This will yield between 128 bits and 256 bits of entropy.
  #
  # NOTE: This also becomes base64 encoded with no padding.
  #
  local rndPass="$( \
  tr -cd '[:alnum:][:punct:]' < /dev/urandom | \
  fold -w$(jot -w %i -r 1 20 40) | \
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

  '"$rndPass"'
  '

  echo "Hashing password..."
  # Generate the encoded hash string from Argon2.
  # Length of 60 uses 384 bits of entropy.
  local hashEnc=$(echo -n $rndPass | argon2 $rndSalt -id -t 5 -m 16 -p 4 -l 60 -e)
  local hashRaw=$(echo -n $rndPass | argon2 $rndSalt -id -t 5 -m 16 -p 4 -l 60 -r)

  echo "Generating encryption data (1/1)..."
  
  # FEK should be kept in memory and purged after operations are complete.
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