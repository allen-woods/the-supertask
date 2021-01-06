#!/bin/sh

extract_openssl_latest_version() {
  # Extract the latest version number from the source download page.
  env SOURCE_VERSION=$( \
    echo "$(curl https://www.openssl.org/source/index.html)" | \
    grep -o '"openssl-.*.tar.gz"' | \
    grep -o '[0-9]\{1\}.[0-9]\{1\}.[0-9]\{1\}[a-z]\{0,\}' | \
    head -n1 \
  )
}

download_and_extract_openssl_latest_version() {
  mkdir -p $HOME/build

  # Download the latest version tarball.
  curl -O https://www.openssl.org/source/openssl-${SOURCE_VERSION}.tar.gz | \
  tar -zx -C $HOME/build
}

enable_aes_wrapping_in_openssl() {
  # Patch OpenSSL to enable AES wrapping (id_aes256_wrap_pad).
  sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' openssl-${SOURCE_VERSION}/apps/enc.c
}

compile_patched_openssl() {
  ./config --prefix=$HOME/local --openssldir=$HOME/local/ssl
  make -j$(grep -c ^processor /proc/cpuinfo)
  make install
}

create_openssl_run_script() {
  cd $HOME/local/bin/

  printf '%s\n' '#!/bin/sh' 'env LD_LIBRARY_PATH=$HOME/local/lib/ $HOME/local/bin/openssl "$@"' > ./openssl.sh
}

create_keys() {
  openssl rand -out payload_aes 32
  openssl rand -out ephemeral_aes 32
  openssl genpkey -out private.pem -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096
  openssl rsa -in private.pem -inform PEM -out public.pem -outform PEM -pubout
  openssl enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < ephemeral_aes) -iv A65959A6 -in payload_aes -out payload_wrapped
  openssl pkeyutl -encrypt -in ephemeral_aes -out ephemeral_wrapped -pubin -inkey public.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha1 -pkeyopt rsa_mgf1_md:sha1
  cat ephemeral_wrapped payload_wrapped > rsa_aes_wrapped
}

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