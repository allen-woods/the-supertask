#!/bin/sh

# Name: install_openssl.sh
# Desc: A collection of shell script functions and commands
#       that are necessary for compiling a AES key-wrap enabled
#       install of OpenSSL 1.1.1k or higher.
#
# NOTE: While these scripts and commands have been authored to be
#       portable wherever possible, this effort is based on current
#       knowledge of POSIX conformance in `/bin/sh`.
#       As such, these scripts can still be improved and should not
#       be considered fully optimized for a given purpose.

check_skip_openssl_install () {
  local CHECK_STR="$( openssl version -a | grep -o 'SSL')"
  [ ! -z "${CHECK_STR}" ] && \
  echo -n "SKIP" || echo -n "INSTALL"
}

add_openssl_instructions_to_queue () {
  printf '%s\n' \
  openssl_apk_add_packages \
  openssl_create_build_dir \
  openssl_create_install_dir \
  openssl_change_to_build_dir \
  openssl_export_wget_source_version \
  openssl_download_source_version \
  openssl_extract_source_version_tar \
  openssl_remove_source_version_tar \
  openssl_enable_aes_wrapping \
  openssl_change_to_source_version_dir \
  openssl_config_version_build \
  openssl_run_make \
  openssl_run_make_test \
  openssl_run_make_install \
  openssl_change_to_binary_dir \
  openssl_create_ld_library_path_script \
  openssl_change_ownership_of_ld_library_path_script \
  openssl_make_ld_library_path_script_executable \
  openssl_change_to_usr_bin_dir \
  openssl_create_dynamic_link_in_usr_bin \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

openssl_apk_add_packages () {
  local ARG=$1
  if [ -z "$( echo -n ${ARG} | sed 's|[0-9]\{1,\}||g' )" ]; then
    [ $ARG -eq 0 ] && [ -z "${APK_FLAGS}" ] && local APK_FLAGS='--quiet --no-progress'
    [ $ARG -eq 2 ] && [ -z "${APK_FLAGS}" ] && local APK_FLAGS='--verbose'
  fi
  apk "${APK_FLAGS}" update
  apk --no-cache "${APK_FLAGS}" add \
    busybox-static=1.32.1-r6 \
    apk-tools-static=2.12.5-r0
  apk.static --no-cache "${APK_FLAGS}" add \
    build-base=0.5-r2 \
    linux-headers=5.7.8-r0 \
    perl=5.32.0-r0 \
    zlib-dev=1.2.11-r3
}
openssl_create_build_dir () {
  [ ! -d $HOME/src ] && \
  mkdir -p $HOME/src
}
openssl_create_install_dir () {
  [ ! -d $HOME/local/ssl ] && \
  mkdir -p $HOME/local/ssl
}
openssl_change_to_build_dir () {
  cd $HOME/src
}
openssl_export_wget_source_version () {
  # Define flags used for silent / verbose.
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && local WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && local WGET_FLAGS='-S'
  # Check health of index link.
  local LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS https://www.openssl.org/source/index.html \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Grab version number if link is alive.
  export OPENSSL_SOURCE_VERSION=$( \
    wget -c $WGET_FLAGS https://www.openssl.org/source/index.html -O - | \
    tr -d '\n' | \
    sed "s/^.*\"\(openssl[-]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[a-zA-Z]\{0,\}\).tar.gz\".*$/\1/g" \
  )
}
openssl_download_source_version () {
  # Define flags used for silent / verbose.
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && local WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && local WGET_FLAGS='-S'
  # Check health of archive link.
  local LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS https://openssl.org/source/${OPENSSL_SOURCE_VERSION}.tar.gz \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Download version if link is alive.
  wget -c $WGET_FLAGS https://openssl.org/source/${OPENSSL_SOURCE_VERSION}.tar.gz
}
openssl_extract_source_version_tar () {
  # Define flags used for silent / verbose.
  [ $1 -eq 2 ] && [ -z "${TAR_FLAGS}" ] && TAR_FLAGS='v'
  tar -xz${TAR_FLAGS}f ${OPENSSL_SOURCE_VERSION}.tar.gz
}
openssl_remove_source_version_tar () {
  rm -f ${OPENSSL_SOURCE_VERSION}.tar.gz
}
openssl_enable_aes_wrapping () {
  # Patch enc.c to enable 'openssl enc -id-aes256-wrap-pad' (RFC 5649, RFC 3394).
  sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' $(pwd)/${OPENSSL_SOURCE_VERSION}/apps/enc.c
}
openssl_change_to_source_version_dir () {
  [ -d $(pwd)/${OPENSSL_SOURCE_VERSION} ] && \
  cd $(pwd)/${OPENSSL_SOURCE_VERSION}
}
openssl_config_version_build () {
  $(pwd)/config \
  --prefix=$HOME/local \
  --openssldir=$HOME/local/ssl \
  no-ssl2 \
  no-ssl3 \
  no-comp \
  no-weak-ssl-ciphers
}
openssl_run_make () {
  # Run parallel jobs based on host system hardware.
  make -j $( \
    grep -c ^processor \
    /proc/cpuinfo \
  )
}
openssl_run_make_test () {
  # Run unit tests.
  make test
}
openssl_run_make_install () {
  # Don't let the install fill up on bread!
  # Software-only build. (no man pages)
  make install_sw
}
openssl_change_to_binary_dir () {
  cd $HOME/local/bin
}
openssl_create_ld_library_path_script () {
  [ ! -f ./openssl.sh ] && \
  echo -e '#!/bin/sh \nenv LD_LIBRARY_PATH=$HOME/local/lib/ $HOME/local/bin/openssl "$@"' > ./openssl.sh
}
openssl_change_ownership_of_ld_library_path_script () {
  chown root:root ./openssl.sh
}
openssl_make_ld_library_path_script_executable () {
  chmod 0755 ./openssl.sh
}
openssl_change_to_usr_bin_dir () {
  cd /usr/bin
}
openssl_create_dynamic_link_in_usr_bin () {
  ln -s $HOME/local/bin/openssl.sh ./aes-wrap
}
openssl_confirm_app_will_run () {
  if [ $1 -gt 0 ]; then
    echo -n "Confirming 'aes-wrap' Will Run: "

    local CHECK_STR=$( aes-wrap version | grep -o 'SSL' )
    [ ! -z "${CHECK_STR}" ] && \
    echo "SUCCESS!" || echo "FAILED."
  fi
}