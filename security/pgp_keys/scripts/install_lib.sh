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
#       All methods must accept a single argument, OPT, whose value is assumed to always be 0, 1, or 2.
#       Evaluations of OPT should be interpreted as follows:
#         - 0: Output of any kind must be silenced using redirection to `/dev/null 2>&1`.
#         - 1: Status messages should be sent to stdout, all other output(s) silenced.
#         - 2: All output should be sent to stdout and `--verbose` options should be applied wherever possible.
#
# * * * BEGIN STANDARDIZED METHODS  * * * * * * * * * * * * * *

check_skip_install() {
  # Steps required to confirm already installed go here.
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
}

read_instruction() {
  read -u3 INSTALL_FUNC_NAME
}

update_instructions() {
  printf '%s\n' "$@" 1>&3
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
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

patch_etc_apk_repositories() { sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories; };
apk_update() { apk update; };
apk_add_busybox_static() { apk add busybox-static; };
apk_add_apk_tools_static() { apk add apk-tools-static; };
apk_static_upgrade_simulate() { apk.static upgrade --no-self-upgrade --available --simulate; };
apk_static_upgrade() { apk.static upgrade --no-self-upgrade --available; };
apk_static_add_build_base() { apk.static add build-base; };
apk_static_add_gnupg() { apk.static add gnupg; };
apk_static_add_perl() { apk.static add perl; };
create_home_build_dir() { mkdir $HOME/build; };
create_home_local_ssl_dir() { mkdir -p $HOME/local/ssl; };
export_openssl_source_version_wget() { export OPENSSL_SOURCE_VERSION="$(wget -c https://www.openssl.org/source/index.html -O -)"; };
openssl_source_version_grep_version_str() { OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | grep -o '\"openssl-.*.tar.gz\"')"; };
openssl_source_version_grep_version_num() { OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | grep -o '[0-9]\{1\}.[0-9]\{1\}.[0-9]\{1\}[a-z]\{0,\}.tar')"; };
openssl_source_version_head_first_result() { OPENSSL_SOURCE_VERSION="$(printf '%s\n' "${OPENSSL_SOURCE_VERSION}" | head -n1)"; };
openssl_source_version_sed_remove_tar() { OPENSSL_SOURCE_VERSION="$(echo ${OPENSSL_SOURCE_VERSION} | sed 's/.tar$//')"; };
change_to_home_build_dir() { cd $HOME/build; };
download_openssl_source_version() { wget -c https://openssl.org/source/openssl-${OPENSSL_SOURCE_VERSION}.tar.gz; };
extract_openssl_source_version() { tar -xzf openssl-${OPENSSL_SOURCE_VERSION}.tar.gz; };
remove_openssl_source_archive() { rm -f openssl-${OPENSSL_SOURCE_VERSION}.tar.gz; };
enable_aes_wrapping_in_openssl() { sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' ./openssl-${OPENSSL_SOURCE_VERSION}/apps/enc.c; };
change_to_home_build_openssl_version_dir() { cd $HOME/build/openssl-${OPENSSL_SOURCE_VERSION}; };
config_openssl_version_build() { ./config --prefix=$HOME/local --openssldir=$HOME/local/ssl; };
make_j_grep_openssl_version_build() { make -j$(grep -c ^processor /proc/cpuinfo); };
make_install_openssl_version_build() { make install; };
change_to_home_local_bin_dir() { cd $HOME/local/bin/; };
create_openssl_version_run_script() { printf '%s\n' '#!/bin/sh' 'export LD_LIBRARY_PATH=$HOME/local/lib/ $HOME/local/bin/openssl "$@"' > ./openssl.sh; };
protect_openssl_version_run_script() { chmod 755 ./openssl.sh; };
create_openssl_version_alias() { alias OPENSSL_V111="$HOME/local/bin/openssl.sh"; };
# Generate phrases - write to pipe
# Generate random payload - write to pipe
# Generate random ephemeral - write to pipe
# Generate private key - write to pipe
# Generate public key - write to pipe
# Wrap phrases in payload (pgp_data.enc) - persist on disk
# Wrap payload in ephemeral - write to pipe
# Wrap ephemeral in public key - write to pipe
# Print ephemeral* and payload* to file (rsa_aes_wrapped) - perist on disk