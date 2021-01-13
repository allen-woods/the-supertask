#!/bin/sh

# TODO: Rewrite these functions to not cd into other directories, or at least to go back to the original directory once finished.

cmd_01() { export SKIP_INSTALL="$(ls -A /pgp/keys/ 2>/dev/null)$(ls -A /pgp/phrases/ 2>/dev/null)"; };
cmd_02() { [ -z $SKIP_INSTALL ] && apk.static add curl; };
cmd_03() { [ -z $SKIP_INSTALL ] && apk.static add gnupg; };
# BEGIN: custom build of OpenSSL with AES wrapping enabled.
cmd_04() { [ -z $SKIP_INSTALL ] && create_openssl_compilation_directories; };
cmd_05() { [ -z $SKIP_INSTALL ] && parse_openssl_latest_version; };
cmd_06() { [ -z $SKIP_INSTALL ] && cd $HOME/build; };
cmd_07() { [ -z $SKIP_INSTALL ] && download_and_extract_openssl_latest_version; };
cmd_08() { [ -z $SKIP_INSTALL ] && enable_aes_wrapping_in_openssl; };
cmd_09() { [ -z $SKIP_INSTALL ] && compile_patched_openssl; };
cmd_10() { [ -z $SKIP_INSTALL ] && create_openssl_run_script; };
cmd_11() { [ -z $SKIP_INSTALL ] && create_openssl_alias; };
# END: custom build of OpenSSL with AES wrapping enabled.
cmd_12() { [ -z $SKIP_INSTALL ] && mkdir -pm 0700 /pgp/keys; };
cmd_13() { [ -z $SKIP_INSTALL ] && mkdir -m 0700 /pgp/phrases; };
# TODO: Write pass phrases to pipe in dedicated function.
cmd_14() { [ -z $SKIP_INSTALL ] && generate_and_run_batch "$(generate_pass_phrases)"; };
cmd_15() { [ -z $SKIP_INSTALL ] && export_keys; };
# Generate payload_aes.
# TODO: Write payload_aes to pipe in dedicated function.
cmd_16() { [ -z $SKIP_INSTALL ] && OPENSSL_V111 rand -out payload_aes 32; };
# Wrap sensitive data in payload_aes. (data*)
# TODO: pipe in "pgp_data.raw".
# TODO: persist "pgp_data.enc".
cmd_17() { [ -z $SKIP_INSTALL ] && OPENSSL_V111 enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < payload_aes) -iv A65959A6 -in pgp_data.raw -out pgp_data.enc; };
# Generate ephemeral_aes.
# TODO: Write "ephemeral_aes" to pipe in dedicated function.
cmd_18() { [ -z $SKIP_INSTALL ] && OPENSSL_V111 rand -out ephemeral_aes 32; };
# Wrap payload_aes in ephemeral_aes. (payload*)
# TODO: pipe in "payload_aes".
# TODO: write "payload_wrapped" to pipe?
cmd_19() { [ -z $SKIP_INSTALL ] && OPENSSL_V111 enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < ephemeral_aes) -iv A65959A6 -in payload_aes -out payload_wrapped; };
# Generate RSA key pair.
# TODO: write keys to pipe in dedicated function(s).
# TODO: perist "public.key".
cmd_20() { [ -z $SKIP_INSTALL ] && OPENSSL_V111 genpkey -out private.pem -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096; };
cmd_21() { [ -z $SKIP_INSTALL ] && OPENSSL_V111 rsa -in private.pem -inform PEM -out public.pem -outform PEM -pubout; };
# Wrap ephemeral_aes in public.key. (ephemeral*)
# TODO: write "ephemeral_wrapped" to pipe in dedicated function.
cmd_22() { [ -z $SKIP_INSTALL ] && OPENSSL_V111 pkeyutl -encrypt -in ephemeral_aes -out ephemeral_wrapped -pubin -inkey public.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha1 -pkeyopt rsa_mgf1_md:sha1; };
# Concatenate ephemeral*, payload* into single file. (rsa_aes_wrapped)
# TODO: pipe "ephemeral_wrapped", "payload_wrapped" into file.
# Resulting Files:
# - data*  the actual data that was encrypted.
# - public.key  the key used to decrypt ephemeral* and payload*.
# - rsa_aes_wrapped  the file containing ephemeral* and payload*.

# Use payload to encrypt pass phrases.
# cmd_08() { [ ! "$(ls -A /pgp/keys/ 2>/dev/null)" ] && pgp_encrypt_pass_phrases; };
cmd_len() { echo 22; };

create_openssl_compilation_directories() {
  mkdir $HOME/build
  mkdir -p $HOME/local/ssl
}

parse_openssl_latest_version() {
  # Extract the latest version number from the source download page.
  export OPENSSL_SOURCE_VERSION=$( \
    echo "$(curl https://www.openssl.org/source/index.html)" | \
    grep -o '"openssl-.*.tar.gz"' | \
    grep -o '[0-9]\{1\}.[0-9]\{1\}.[0-9]\{1\}[a-z]\{0,\}' | \
    head -n1 \
  )
  echo "Found Version: ${OPENSSL_SOURCE_VERSION}"
}

download_and_extract_openssl_latest_version() {
  curl -O https://www.openssl.org/source/openssl-${OPENSSL_SOURCE_VERSION}.tar.gz
  tar -zxf openssl-${OPENSSL_SOURCE_VERSION}.tar.gz
  rm -f openssl-${OPENSSL_SOURCE_VERSION}.tar.gz
  echo "$(ls -la .)"
}

enable_aes_wrapping_in_openssl() {
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
  local PUBLIC= # Public RSA key; see below.

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