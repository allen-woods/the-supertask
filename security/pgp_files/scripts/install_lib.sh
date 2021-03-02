#!/bin/sh

# Name: install_lib.sh
# Desc: A collection of methods that must be called in proper sequence to install a specific set of data.
#       Certain methods are standardized and must appear, as follows:
#         - check_skip_install    A method for checking if the install should be skipped.
#         - create_instructions   A method for creating a non-blocking pipe to store instruction names.
#         - read_instruction      A method for reading instruction names from the non-blocking pipe.
#         - update_instructions   A method for placing instruction names into the non-blocking pipe.
#         - delete_instructions   A method for deleting the non-blocking pipe and any instructions inside.
#         - pretty_print          A method for printing text in a concise, colorful, "pretty" way.
#
#       `create_instructions` must accept a single argument, OPT, whose value is always 0, 1, or 2.
#       Evaluations of OPT should be interpreted as follows:
#         - 0: Output of any kind must be silenced using redirection to `/dev/null 2>&1`.
#         - 1: Status messages should be sent to stdout, all other output(s) silenced.
#         - 2: All output should be sent to stdout and `--verbose` options should be applied wherever possible.
#
# * * * BEGIN STANDARDIZED METHODS  * * * * * * * * * * * * * *

check_skip_install() {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

create_instructions() {
  local OPT=$1
  case $OPT in
    0)
      # completely silent * * * * * * * * * * * * * * * * * * *
      #
      exec 4>/dev/null  # stdout:   disabled  (Shell process)
      exec 5>/dev/null  # echo:     disabled  (Status command)
      exec 2>/dev/null  # stderr:   disabled
      set +v #          # verbose:  disabled
      ;;
    1)
      # status only * * * * * * * * * * * * * * * * * * * * * *
      #
      exec 4>/dev/null  # stdout:   disabled  (Shell process)
      exec 5>&1         # echo:     ENABLED   (Status command)
      exec 2>/dev/null  # stderr:   disabled
      set +v #          # verbose:  disabled
      ;;
    2)
      # verbose * * * * * * * * * * * * * * * * * * * * * * * *
      #
      exec 4>&1         # stdout:   ENABLED   (Shell process)
      exec 5>&1         # echo:     ENABLED   (Status command)
      exec 2>&1         # stderr:   ENABLED
      set -v #          # verbose:  ENABLED
      ;;
    *)
      # do nothing  * * * * * * * * * * * * * * * * * * * * * *
      #
  esac

  mkfifo /tmp/instructs 1>&4
  echo "Created pipe for instructions." 1>&5

  exec 3<> /tmp/instructs 1>&4
  echo "Executed file descriptor to unblock pipe." 1>&5

  unlink /tmp/instructs 1>&4
  echo "Unlinked the unblocked pipe." 1>&5

  $(echo ' ' 1>&3) 1>&4
  echo "Inserted blank space into unblocked pipe." 1>&5
}

read_instruction() {
  read -u 3 INSTALL_FUNC_NAME

}

update_instructions() {
  printf '%s\n' \
  apk_add_busybox_static \
  apk_add_apk_tools_static \
  apk_static_add_build_base \
  apk_static_add_gnupg \
  apk_static_add_linux_headers \
  apk_static_add_outils_jot \
  apk_static_add_perl \
  create_home_build_dir \
  create_home_local_ssl_dir \
  export_openssl_source_version_wget \
  openssl_source_version_grep_version_str \
  openssl_source_version_grep_version_num \
  openssl_source_version_head_first_result \
  openssl_source_version_sed_remove_tar \
  change_to_home_build_dir \
  download_openssl_source_version \
  extract_openssl_source_version_tar \
  remove_openssl_source_version_tar \
  enable_aes_wrapping_in_openssl \
  change_to_home_build_openssl_version_dir \
  config_openssl_version_build \
  make_j_grep_openssl_version_build \
  make_install_openssl_version_build \
  export_ld_library_path \
  export_openssl_v111 \
  verify_openssl_version \
  generate_asc_key_data \
  generate_payload_aes \
  generate_ephemeral_aes \
  generate_private_rsa \
  generate_public_rsa \
  enc_phrases_with_payload \
  wrap_payload_in_ephemeral \
  wrap_ephemeral_in_public_key \
  persist_rsa_aes_wrapped \
  EOP \
  ' ' 1>&3
}

delete_instructions() {
  exec 2>&1             # Restore stderr
  exec 3>&-             # Remove file descriptor 3
  exec 4>&-             # Remove file descriptor 4
  exec 5>&-             # Remove file descriptor 5
  rm -f /tmp/instructs  # Force deletion of pipe
  set +v #              # Cancel verbose mode
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

# patch_etc_apk_repositories() {
#   # not used
#   sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories 1>&4
#   echo -e "\033[7;33mPatched Alpine to Latest Stable\033[0m" 1>&5 # These are status messages that have fg/bg commands (colors).
# }
# apk_update() {
#   # not used
#   apk update 1>&4
#   echo -e "\033[7;33mApk Update\033[0m" 1>&5
# }
apk_add_busybox_static() {
  apk add busybox-static 1>&4
  echo -e "\033[7;33mAdded BusyBox Static Tools\033[0m" 1>&5
}
apk_add_apk_tools_static() {
  apk add apk-tools-static 1>&4
  echo -e "\033[7;33mAdded APK Static Tools\033[0m" 1>&5
}
# apk_static_upgrade_simulate() {
#   # not used
#   apk.static upgrade --no-self-upgrade --available --simulate 1>&4
#   echo -e "\033[7;33mChecked for Problems in Alpine Upgrade\033[0m" 1>&5
# }
# apk_static_upgrade() {
#   # not used
#   apk.static upgrade --no-self-upgrade --available 1>&4
#   echo -e "\033[7;33mProceeded with Alpine Upgrade\033[0m" 1>&5
# }
apk_static_add_build_base() {
  apk.static add build-base 1>&4
  echo -e "\033[7;33mAdded Build Base\033[0m" 1>&5
}
apk_static_add_gnupg() {
  apk.static add gnupg 1>&4
  echo -e "\033[7;33mAdded GnuPG\033[0m" 1>&5
}
apk_static_add_linux_headers() {
  apk.static add linux-headers 1>&4
  echo -e "\033[7;33mAdded Linux Headers\033[0m" 1>&5
}
apk_static_add_outils_jot() {
  apk.static add outils-jot 1>&4
  echo -e "\033[7;33mAdded OUtils-Jot\033[0m" 1>&5
}
apk_static_add_perl() {
  apk.static add perl 1>&4
  echo -e "\033[7;33mAdded Perl\033[0m" 1>&5
}
create_home_build_dir() {
  mkdir $HOME/build 1>&4
  echo -e "\033[7;33mCreated ${HOME}/build directory\033[0m" 1>&5
}
create_home_local_ssl_dir() {
  mkdir -p $HOME/local/ssl 1>&4
  echo -e "\033[7;33mCreated ${HOME}/local/ssl directory\033[0m" 1>&5
}
export_openssl_source_version_wget() {
  export OPENSSL_SOURCE_VERSION="$(wget -c https://www.openssl.org/source/index.html -O -)" 1>&4
  echo -e "\033[7;33mSaved OpenSSL.org HTML File to Variable Using WGET\033[0m" 1>&5
}
openssl_source_version_grep_version_str() {
  OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | grep -o '\"openssl-.*.tar.gz\"')" 1>&4
  echo -e "\033[7;33mParsed OpenSSL Version Strings from HTML Syntax\033[0m" 1>&5
}
openssl_source_version_grep_version_num() {
  OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | grep -o '[0-9]\{1\}.[0-9]\{1\}.[0-9]\{1\}[a-z]\{0,\}.tar')" 1>&4
  echo -e "\033[7;33mParsed OpenSSL Version Release Numbers from Strings\033[0m" 1>&5
}
openssl_source_version_head_first_result() {
  OPENSSL_SOURCE_VERSION="$(printf '%s\n' "${OPENSSL_SOURCE_VERSION}" | head -n1)" 1>&4
  echo -e "\033[7;33mParsed Latest Stable Version of OpenSSL from Release Numbers\033[0m" 1>&5
}
openssl_source_version_sed_remove_tar() {
  OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | sed 's/.tar$//g')" 1>&4
  echo -e "\033[7;33mRemoved Unwanted Trailing Data from Latest Stable\033[0m" 1>&5
}
change_to_home_build_dir() {
  cd $HOME/build 1>&4
  echo -e "\033[7;33mChanged Current Directory to ${HOME}/build\033[0m" 1>&5
}
download_openssl_source_version() {
  wget -c https://openssl.org/source/openssl-${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mDownloaded Source TAR for Latest Stable OpenSSL\033[0m" 1>&5
}
extract_openssl_source_version_tar() {
  tar -xzf openssl-${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mExtracted Source TAR for Latest Stable OpenSSL\033[0m" 1>&5
}
remove_openssl_source_version_tar() {
  rm -f openssl-${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mForced Removal of Source TAR File\033[0m" 1>&5
}
enable_aes_wrapping_in_openssl() {
  sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' ./openssl-${OPENSSL_SOURCE_VERSION}/apps/enc.c 1>&4
  echo -e "\033[7;33mPatched OpenSSL to Enable AES Wrapping\033[0m" 1>&5
}
change_to_home_build_openssl_version_dir() {
  cd $HOME/build/openssl-${OPENSSL_SOURCE_VERSION} 1>&4
  echo -e "\033[7;33mChanged Current Directory to ${HOME}/build/openssl-${OPENSSL_SOURCE_VERSION}\033[0m" 1>&5
}
config_openssl_version_build() {
  ./config --prefix=$HOME/local --openssldir=$HOME/local/ssl 1>&4
  echo -e "\033[7;33mConfigured Build of OpenSSL\033[0m" 1>&5
}
make_j_grep_openssl_version_build() {
  make -j$(grep -c ^processor /proc/cpuinfo) 1>&4
  echo -e "\033[7;33mRan Make With -j Option\033[0m" 1>&5
}
make_install_openssl_version_build() {
  make install 1>&4
  echo -e "\033[7;33mRan Make Install to Build OpenSSL\033[0m" 1>&5
}
export_ld_library_path() {
  export LD_LIBRARY_PATH=$HOME/local/lib/ 1>&4
  echo -e "\033[7;33mExported LD_LIBRARY_PATH Env Var\033[0m" 1>&5
}
export_openssl_v111() {
  export OPENSSL_V111=$HOME/local/bin/openssl 1>&4
  echo -e "\033[7;33mExported OPENSSL_V111 Env Var\033[0m" 1>&5
}
verify_openssl_version() {
  $OPENSSL_V111 version 1>&4
  echo -e "\033[7;33mVerified OpenSSL Version\033[0m" 1>&5
}
generate_asc_key_data() {
  # ......................... Default number of iterations is 4.
  local max_iter=4
  # ......................... Begin on iteration 1.
  local iter=1
  # ......................... Where the batch file should be stored.
  local batch_dir=/tmp/pgpb
  # ......................... If the dir doesn't exist,
  if [ ! -d "${batch_dir}" ]; then
    # ....................... Make it.
    mkdir -p "${batch_dir}" 1>&4
  fi
  # ......................... Where the key files should be stored.
  local key_dest_dir=/pgp/keys
  # ......................... If the dir doesn't exist,
  if [ ! -d "${key_dest_dir}" ]; then
    # ....................... Make it.
    mkdir -p "${key_dest_dir}" 1>&4
  fi
  # ......................... Reserve a pipe to store our data in.
  pipe_crud -c -P=pgp_data -D=pgp_keys --secure
  # ......................... Iterate from 1 to N.
  while [ $iter -le $max_iter ]; do
    # ....................... Generate unique, random batch file.
    local batch_file=${batch_dir}/.$(tr -cd a-f0-9 < /dev/urandom | fold -w16 | head -n1)
    # ....................... Generate random phrase length.
    local phrase_len=$(jot -w %i -r 1 20 99)
    # ....................... Generate random phrase.
    local phrase=$(tr -cd [[:alnum:][:punct:]] < /dev/urandom | fold -w${phrase_len} | head -n1)
    # ....................... Format the key number based on length and value of N.
    local iter_str=$(printf '%0'"${#max_iter}"'d' ${iter})
    # ....................... Delare a message to display when each key is done.
    local done_msg=
    # ....................... conditionally assign a value to the done message.
    [ $iter -eq $max_iter ] && done_msg="%echo Done!" || done_msg="%echo Key Details Complete."
    # ....................... Print the contents of eah batch.
    printf '%s\n' \
      "%echo Generating Key [ $iter / $max_iter ]" \
      "Key-Type: RSA" \
      "Key-Length: 4096" \
      "Subkey-Type: RSA" \
      "Subkey-Length: 4096" \
      "Passphrase: ${phrase}" \
      "Name-Real: ${name_real:-Thomas Tester}" \
      "Name-Email: ${name_email:-test@thesupertask.com}" \
      "Name-Comment: ${name_comment:-Auto-generated Key Used for Testing.}" \
      "Expire-Date: 0" \
      "%commit" \
    "${done_msg}" >> $batch_file
    # ....................... Put sensitive data into the pipe first.
    pipe_crud -u -P=pgp_data -D=pgp_keys -I={\"key_${iter_str}_asc\":\"$(echo "${phrase}" | base64 | tr -d '\n' | sed 's/ //g')\"} 2>/dev/null
    # ....................... Generate the Nth key.
    gpg2 \
      --verbose \
      --batch \
    --gen-key $batch_file 1>&4
    #
    sleep 1s # .............. SLEEP
    #
    # ....................... Delete the batch file.
    rm -f $batch_file 1>&4
    # ....................... Identify the newest key made.
    local revoc_file="$(ls -t ${HOME}/.gnupg/openpgp-revocs.d | head -n1)"
    # ....................... Export the newest key.
    gpg2 \
      --export \
      "$(basename ${revoc_file} | cut -f1 -d '.')" | \
    base64 > "${key_dest_dir}/key_${iter_str}.asc"
    # ....................... Increment plus one.
    iter=$(($iter + 1))
  done
  # ......................... Give the user feedback.
  echo -e "\033[7;33mGenerated PGP Data\033[0m" 1>&5
}
generate_payload_aes() {
  local PAYLOAD="$( \
    $OPENSSL_V111 rand 32 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  pipe_crud -c -P=pgp_data -D=payload -I={\"aes\":\"${PAYLOAD}\"} 1>&4
  echo "payload: $(pipe_crud -r -P=pgp_data -D=payload -I={\"aes\"} | base64 -d)"
  echo "original: $(echo ${PAYLOAD} | base64 -d)"
  echo -e "\033[7;33mGenerated Random Payload\033[0m" 1>&5
}
generate_ephemeral_aes() {
  local EPHEMERAL="$( \
    $OPENSSL_V111 rand 32 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  pipe_crud -c -P=pgp_data -D=ephemeral -I={\"aes\":\"${EPHEMERAL}\"} 1>&4
  echo "ephemeral: $(pipe_crud -r -P=pgp_data -D=ephemeral -I={\"aes\"} | base64 -d)"
  echo "original: $(echo ${EPHEMERAL} | base64 -d)"
  echo -e "\033[7;33mGenerated Random Ephemeral\033[0m" 1>&5
}
generate_private_rsa() {
  local PRIVATE_KEY="$( \
    $OPENSSL_V111 genpkey \
    -outform PEM \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:4096 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  pipe_crud -c -P=pgp_data -D=private_rsa -I={\"key\":\"${PRIVATE_KEY}\"} 1>&4
  echo "private rsa: $(pipe_crud -r -P=pgp_data -D=private_rsa -I={\"key\"} | base64 -d)"
  echo -e "\033[7;33mGenerated Private Key\033[0m" 1>&5
}
generate_public_rsa() {
  local PRIVATE_KEY="$( \
    pipe_crud -r -P=pgp_data -D=private_rsa -I={\"key\"} | \
    base64 -d \
  )"
  local PUB_KEY="$( \
    echo "${PRIVATE_KEY}" | \
    $OPENSSL_V111 rsa -inform PEM -outform PEM -pubout | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  pipe_crud -c -P=pgp_data -D=public_rsa -I={\"key\":\"${PUB_KEY}\"} 1>&4
  echo "public rsa: $(pipe_crud -r -P=pgp_data -D=public_rsa -I={\"key\"} | base64 -d)"
  echo -e "\033[7;33mGenerated Public Key\033[0m" 1>&5
}
enc_phrases_with_payload() {
  local PAYLOAD_HEX="$( \
    pipe_crud -r -P=pgp_data -D=payload -I={\"aes\"} | \
    base64 -d | \
    hexdump -v -e '/1 "%02X"' \
  )"
  local PGP_KEYS="$( \
    pipe_crud -r -P=pgp_data -D=pgp_keys \
  )"
  echo "${PGP_KEYS}" | $OPENSSL_V111 enc -id-aes256-wrap-pad -K ${PAYLOAD_HEX} -iv A65959A6 -out /pgp/keys/phrases_wrapped 1>&4
  echo -e "\033[7;33mEncrypted PGP Key Pass Phrases with Payload AES\033[0m" 1>&5
}
wrap_payload_in_ephemeral() {
  local PAYLOAD_AES="$( \
    pipe_crud -r -P=pgp_data -D=payload -I={\"aes\"} | \
    base64 -d \
  )"
  local EPHEMERAL_HEX="$( \
    pipe_crud -r -P=pgp_data -D=ephemeral -I={\"aes\"} | \
    base64 -d | \
    hexdump -v -e '/1 "%02X"' \
  )"
  local PAYLOAD_WRAPPED="$( \
    echo "${PAYLOAD_AES}" | \
    $OPENSSL_V111 enc -id-aes256-wrap-pad \
    -K "${EPHEMERAL_HEX}" \
    -iv A65959A6 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  pipe_crud -c -P=pgp_data -D=payload_wrapped -I={\"enc\":\"${PAYLOAD_WRAPPED}\"}
  echo "payload_wrapped: $(pipe_crud -r -P=pgp_data -D=payload_wrapped -I={\"enc\"} | base64 -d)"
  echo -e "\033[7;33mWrapped Payload AES with Ephemeral AES\033[0m" 1>&5
}
wrap_ephemeral_in_public_key() {
  local EPHEMERAL_AES="$( \
    pipe_crud -r -P=pgp_data -D=ephemeral -I={\"aes\"} | \
    base64 -d \
  )"
  local PUB_KEY="$( \
    pipe_crud -r -P=pgp_data -D=public_rsa -I={\"key\"} | \
    base64 -d \
  )"
  mkfifo public_pem
  ( echo "${PUB_KEY}" > public_pem & )
  local EPHEMERAL_WRAPPED="$( \
    echo "${EPHEMERAL_AES}" | \
    $OPENSSL_V111 pkeyutl \
    -encrypt \
    -pubin -inkey public_pem \
    -pkeyopt rsa_padding_mode:oaep \
    -pkeyopt rsa_oaep_md:sha1 \
    -pkeyopt rsa_mgf1_md:sha1 | \
    base64 | tr -d '\n' | sed 's/ //g' \
  )"
  ( rm -f public_pem )
  pipe_crud -c -P=pgp_data -D=ephemeral_wrapped -I={\"enc\":\"${EPHEMERAL_WRAPPED}\"}
  echo "ephemeral_wrapped: $(pipe_crud -r -P=pgp_data -D=ephemeral_wrapped -I={\"enc\"} | base64 -d)"
  echo -e "\033[7;33mWrapped Ephemeral AES with Public Key\033[0m" 1>&5
}
persist_rsa_aes_wrapped() {
  local EPHEMERAL_WRAPPED="$( \
    pipe_crud -r -P=pgp_data -D=ephemeral_wrapped -I={\"enc\"} | \
    base64 -d \
  )"
  local PAYLOAD_WRAPPED="$( \
    pipe_crud -r -P=pgp_data -D=payload_wrapped -I={\"enc\"} | \
    base64 -d \
  )"
  echo ${EPHEMERAL_WRAPPED} >> /pgp/rsa_aes_wrapped
  echo ${PAYLOAD_WRAPPED} >> /pgp/rsa_aes_wrapped
  cat /pgp/rsa_aes_wrapped
  echo -e "\033[7;33mPrinted RSA AES Wrapped Data to File\033[0m" 1>&5
}

# NOTE:
# These Commented functions are retained for completeness where they originally appeared.
# Use of the commented functions causes catastrophic failure of DieHarder's `make install` process,
# so I'm standardizing their non-use for consistency.
#
# patch_etc_apk_repositories() {
#   sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories 1>&4
#   echo -e "\033[7;33mPatched Alpine to Latest Stable\033[0m" 1>&5 # These are status messages that have fg/bg commands (colors).
# }
# apk_update() {
#   apk update 1>&4
#   echo -e "\033[7;33mApk Update\033[0m" 1>&5
# }
# apk_static_upgrade_simulate() {
#   apk.static upgrade --no-self-upgrade --available --simulate 1>&4
#   echo -e "\033[7;33mChecked for Problems in Alpine Upgrade\033[0m" 1>&5
# }
# apk_static_upgrade() {
#   apk.static upgrade --no-self-upgrade --available 1>&4
#   echo -e "\033[7;33mProceeded with Alpine Upgrade\033[0m" 1>&5
# }