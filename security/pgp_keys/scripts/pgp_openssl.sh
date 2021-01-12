#!/bin/sh

parse_openssl_latest_version() {
  # Extract the latest version number from the source download page.
  export OPENSSL_SOURCE_VERSION=$( \
    echo "$(curl https://www.openssl.org/source/index.html)" | \
    grep -o '"openssl-.*.tar.gz"' | \
    grep -o '[0-9]\{1\}.[0-9]\{1\}.[0-9]\{1\}[a-z]\{0,\}' | \
    head -n1 \
  )
}

download_and_extract_openssl_latest_version() {
  mkdir -p $HOME/build
  curl -O https://www.openssl.org/source/openssl-${OPENSSL_SOURCE_VERSION}.tar.gz | \
  tar -zx -C $HOME/build
}

enable_aes_wrapping_in_openssl() {
  cd $HOME/build
  sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' ./openssl-${OPENSSL_SOURCE_VERSION}/apps/enc.c
}

compile_patched_openssl() {
  ./config --prefix=$HOME/local --openssldir=$HOME/local/ssl
  make -j$(grep -c ^processor /proc/cpuinfo)
  make install
}

create_openssl_run_script() {
  cd $HOME/local/bin/
  printf '%s\n' '#!/bin/sh' 'export LD_LIBRARY_PATH=$HOME/local/lib/ $HOME/local/bin/openssl "$@"' > ./openssl.sh
  chmod 755 ./openssl.sh
}

create_openssl_alias() {
  alias OPENSSL_V111="$HOME/local/bin/openssl.sh"
}

generate_and_enrypt_pgp_data() {
  local PHRASES="$(generate_pass_phrases)"  # Pass phrases for PGP keys.
  local PAYLOAD="$(OPENSSL_V111 rand 32)"   # Payload AES key used to encrypt data.
  local EPHEMERAL="$(OPENSSL_V111 rand 32)" # Ephemeral AES key used to wrap payload key.
  # Private RSA key.
  local PRIVATE="$(OPENSSL_V111 genpkey \
  -outform PEM \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096)"
  # Public RSA key; see below.
  local PUBLIC=

  # Write private key to pipe to be able to create public key.
  pipe_write "/tmp/.private" ''"${PRIVATE}"'' --append
  # Generate public key.
  PUBLIC="$(OPENSSL_V111 rsa -in /tmp/.private -inform PEM -outform PEM -pubout)"
  # Wrap pass phrases in payload AES key.
  OPENSSL_V111 enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < $PAYLOAD) -iv A65959A6 -in .tmp -out pgp_data.enc
  # Wrap payload AES key in ephemeral AES key.
  local PAYLOAD_ENC="$(OPENSSL_V111 enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < ${EPHEMERAL}) -iv A65959A6 -in .tmp)"
  # Wrap ephemeral AES key in public RSA key
  local EPHEMERAL_ENC="$(OPENSSL_V111 pkeyutl -encrypt -in )"
  # Print EPHEMERAL_ENC, PAYLOAD_ENC into rsa_aes_wrapped
  cat $EPHEMERAL_ENC $PAYLOAD_ENC > wrapper
}

# TODO: Create individual functions for each line below.
create_keys() {
  openssl rand -out payload_aes 32
  openssl rand -out ephemeral_aes 32
  openssl genpkey -out private.pem -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096
  openssl rsa -in private.pem -inform PEM -out public.pem -outform PEM -pubout
  openssl enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < ephemeral_aes) -iv A65959A6 -in payload_aes -out payload_wrapped
  openssl pkeyutl -encrypt -in ephemeral_aes -out ephemeral_wrapped -pubin -inkey public.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha1 -pkeyopt rsa_mgf1_md:sha1
  cat ephemeral_wrapped payload_wrapped > rsa_aes_wrapped
}