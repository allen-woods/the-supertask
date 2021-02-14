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
  change_to_home_local_bin_dir \
  create_openssl_version_run_script \
  protect_openssl_version_run_script \
  create_openssl_version_alias \
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

# EXAMPLE SYNTAX:
# pretty_print  -H|--header -N|--name="name of setion"  -D|--desc="desription of section"
# pretty_print  -B|--body   -M|--message="message text" -C|--class="class_name"
# pretty_print  -F|--footer -T|--text="text to display"

# TODO: Write `pretty_print`

pretty_print() {
  local OPT_1=$1
  case $OPT_1 in
    -H|--header)
    ;;
    -B|--body)
    ;;
    -F|--footer)
    ;;
    *)
    # Do nothing
    ;;
  esac
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

patch_etc_apk_repositories() {
  sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories 1>&4
  echo -e "\033[7;33mPatched Alpine to Latest Stable\033[0m" 1>&5 # These are status messages that have fg/bg commands (colors).
}
apk_update() {
  apk update 1>&4
  echo -e "\033[7;33mApk Update\033[0m" 1>&5
}
apk_add_busybox_static() {
  apk add busybox-static 1>&4
  echo -e "\033[7;33mAdded BusyBox Static Tools\033[0m" 1>&5
}
apk_add_apk_tools_static() {
  apk add apk-tools-static 1>&4
  echo -e "\033[7;33mAdded APK Static Tools\033[0m" 1>&5
}
apk_static_upgrade_simulate() {
  apk.static upgrade --no-self-upgrade --available --simulate 1>&4
  echo -e "\033[7;33mChecked for Problems in Alpine Upgrade\033[0m" 1>&5
}
apk_static_upgrade() {
  apk.static upgrade --no-self-upgrade --available 1>&4
  echo -e "\033[7;33mProceeded with Alpine Upgrade\033[0m" 1>&5
}
apk_static_add_build_base() {
  apk.static add build-base 1>&4
  echo -e "\033[7;33mAdded Build Base\033[0m" 1>&5
}
apk_static_add_gcc() {
  # Unused, included for completeness.
  apk.static add gcc 1>&4
  echo -e "\033[7;33mAdded GCC\033[0m" 1>&5
}
apk_static_add_gnupg() {
  apk.static add gnupg 1>&4
  echo -e "\033[7;33mAdded GnuPG\033[0m" 1>&5
}
apk_static_add_linux_headers() {
  apk.static add linux-headers 1>&4
  echo -e "\033[7;33mAdded Linux Headers\033[0m" 1>&5
}
apk_static_add_make() {
  # Unused, included for completeness.
  apk.static add make 1>&4
  echo -e "\033[7;33mAdded Make\033[0m" a>&5
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
  OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | sed 's/.tar$//')" 1>&4
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
  echo -e "Ran Make With -j Option" 1>&5
}
make_openssl_version_build() {
  # Unused, included for completeness.
  make 1>&4
  echo -e "\033[7;33mRan Make With No Arguments\033[0m" 1>&5
}
make_test_openssl_version_build() {
  # Unused, included for completeness.
  make test 1>&4
  echo -e "\033[7;33mRan Make Test\033[0m" 1>&5
}
make_install_openssl_version_build() {
  make install 1>&4
  echo -e "\033[7;33mRan Make Install to Build OpenSSL\033[0m" 1>&5
}
change_to_home_local_bin_dir() {
  cd $HOME/local/bin/ 1>&4
  echo -e "\033[7;33mChanged Current Directory to ${HOME}/local/bin\033[0m" 1>&5
}
create_openssl_version_run_script() {
  printf '%s\n' '#!/bin/sh' 'export LD_LIBRARY_PATH=$HOME/local/lib/ $HOME/local/bin/openssl "$@"' > ./openssl.sh 1>&4
  echo -e "\033[7;33mCreated OpenSSL Run Script\033[0m" 1>&5
}
protect_openssl_version_run_script() {
  chmod 755 ./openssl.sh 1>&4
  echo -e "\033[7;33mProtected Run Script Using CHMOD\033[0m" 1>&5
}
create_openssl_version_alias() {
  alias OPENSSL_V111="$HOME/local/bin/openssl.sh" 1>&4
  echo -e "\033[7;33mCreated Alias for AES Wrap Enabled OpenSSL\033[0m" 1>&5
}
generate_pass_phrases_for_pgp_keys() {
  pipe_crud -c \
  -P=pgp_data \
  -D=phrases \
  -I={\"key_01\":\"$(tr -cd [[:alnum:][:punct:]] < /dev/urandom | fold -w$(jot -w %i -r 1 20 99) | head -n1)\", } \
  --secure 1>&4
  echo -e "\033[7;33mGenerated Pass Phrases for PGP Keys\033[0m" 1>&5
}
generate_random_payload() {
  pipe_crud -u \
  -P=pgp_data \
  -D=payload \
  -I={\"base64_enc_data\":\"openssl_data_here\"} 1>&4
  echo -e "\033[7;33mGenerated Random Payload\033[0m" 1>&5
}
generate_random_ephemeral() {
  pipe_crud -u \
  -P=pgp_data \
  -D=ephemeral \
  -I={\"base64_enc_data\":\"openssl_data_here\"} 1>&4
  echo -e "\033[7;33mGenerated Random Ephemeral\033[0m" 1>&5
}
generate_private_key() {
  pipe_crud -u \
  -P=pgp_data \
  -D=RSA \
  -I={\"private_key\":\"openssl_data_here\"} 1>&4
  echo -e "\033[7;33mGenerated Private Key\033[0m" 1>&5
}
generate_public_key() {
  pipe_crud -u \
  -P=pgp_data \
  -D=RSA \
  -I={\"public_key\":\"openssl_data_here\"} 1>&4
  echo -e "\033[7;33mGenerated Public Key\033[0m" 1>&5
}
wrap_phrases_in_payload() {
  #
} # persist file?
wrap_payload_in_ephemeral() {
  #
}
wrap_ephemeral_in_public_key() {
  #
}
print_ephemeral_enc_payload_enc_to_file() {
  #
} # persist file

# Generate phrases - write to pipe
# Generate random payload - write to pipe
# Generate random ephemeral - write to pipe
# Generate private key - write to pipe
# Generate public key - write to pipe
# Wrap phrases in payload (pgp_data.enc) - persist on disk
# Wrap payload in ephemeral - write to pipe
# Wrap ephemeral in public key - write to pipe
# Print ephemeral* and payload* to file (rsa_aes_wrapped) - perist on disk

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