#!/bin/sh

# NAME: install_openssl.sh
# DESC: A script containing instructions for generating an AES wrap-enabled build of the latest release of OpenSSL.

export OPENSSL_BUILD_DIR=$HOME/src
export OPENSSL_PREFIX_DIR=$HOME/local
export OPENSSL_INSTALL_DIR=$HOME/local/ssl
export OPENSSL_BINARY_DIR=$HOME/local/bin
export OPENSSL_LIB_DIR=$HOME/local/lib
export OPENSSL_INDEX_URL=https://www.openssl.org/source/index.html
export OPENSSL_SRC_URL=https://openssl.org/source/
export OPENSSL_SRC_EXT=.tar.gz
export OPENSSL_PATCH_FILE_PATH=/apps/enc.c
export OPENSSL_USR_LOCAL_SSL_DIR=/usr/local/ssl
export OPENSSL_LINK_LIBRARY_CONF_DIR=/etc/ld.so.conf.d
export OPENSSL_CONF_EXT=.conf
export OPENSSL_USR_BIN_REHASH_PATH=/usr/bin/c_rehash
export OPENSSL_USR_BIN_OPENSSL_PATH=/usr/bin/openssl
export OPENSSL_BACKUP_EXT=.BACKUP

check_skip_openssl_install() {
  local CHECK_STR="$( openssl version -a | grep -o 'SSL')"
  [ ! -z "${CHECK_STR}" ] && \
  echo -n "SKIP" || echo -n "INSTALL"
}

add_openssl_instructions_to_queue() {
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
  openssl_confirm_app_will_run \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

openssl_apk_add_packages() {
  local APK_FLAGS=
  [ $1 -eq 0 ] && [ -z "${APK_FLAGS}" ] && APK_FLAGS='--quiet --no-progress'
  [ $1 -eq 2 ] && [ -z "${APK_FLAGS}" ] && APK_FLAGS='--verbose'
  apk ${APK_FLAGS} \
  update && \
  apk ${APK_FLAGS} \
  upgrade && \
  apk ${APK_FLAGS} \
  --no-cache add \
    busybox-static \
    apk-tools-static && \
  apk.static ${APK_FLAGS} \
  --no-cache add \
    build-base \
    linux-headers \
    openssl \
    perl \
    zlib-dev
}
openssl_create_build_dir() {
  [ ! -d $OPENSSL_BUILD_DIR ] && \
  mkdir -p $OPENSSL_BUILD_DIR
}
openssl_create_install_dir() {
  [ ! -d $OPENSSL_INSTALL_DIR ] && \
  mkdir -p $OPENSSL_INSTALL_DIR
}
openssl_change_to_build_dir() {
  cd $OPENSSL_BUILD_DIR
}
openssl_export_wget_source_version() {
  # Define flags used for silent / verbose.
  local WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of index link.
  local LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS $OPENSSL_INDEX_URL \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Grab version number if link is alive.
  export OPENSSL_SOURCE_VERSION=$( \
    wget -c $WGET_FLAGS $OPENSSL_INDEX_URL -O - | \
    tr -d '\n' | \
    sed "s/^.*\"\(openssl[-]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[a-zA-Z]\{0,\}\)${OPENSSL_SRC_EXT}\".*$/\1/g" \
  )
}
openssl_download_source_version() {
  # Define flags used for silent / verbose.
  local WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of index link.
  local LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS ${OPENSSL_SRC_URL}${OPENSSL_SOURCE_VERSION}${OPENSSL_SRC_EXT} \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Download version if link is alive.
  wget -c $WGET_FLAGS ${OPENSSL_SRC_URL}${OPENSSL_SOURCE_VERSION}${OPENSSL_SRC_EXT}
}
openssl_extract_source_version_tar() {
  # Define flags used for silent / verbose.
  local TAR_FLAGS=
  [ $1 -eq 2 ] && [ -z "${TAR_FLAGS}" ] && TAR_FLAGS='v'
  tar -xz${TAR_FLAGS}f ${OPENSSL_SOURCE_VERSION}${OPENSSL_SRC_EXT}
}
openssl_remove_source_version_tar() {
  rm -f ${OPENSSL_SOURCE_VERSION}${OPENSSL_SRC_EXT}
}
openssl_enable_aes_wrapping() {
  # Patch enc.c to enable 'openssl enc -id-aes256-wrap-pad' (RFC 5649, RFC 3394).
  sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' $(pwd)/${OPENSSL_SOURCE_VERSION}${OPENSSL_PATCH_FILE_PATH}
}
openssl_change_to_source_version_dir() {
  [ -d $(pwd)/${OPENSSL_SOURCE_VERSION} ] && \
  cd $(pwd)/${OPENSSL_SOURCE_VERSION}
}
openssl_config_version_build() {
  ./config \
  --prefix=${OPENSSL_PREFIX_DIR} \
  --openssldir=${OPENSSL_INSTALL_DIR} \
  # no-ssl2 \
  # no-ssl3 \
  # no-weak-ssl-ciphers
}
openssl_run_make() {
  # Run parallel jobs based on host system hardware.
  make -j$( \
    grep -c ^processor \
    /proc/cpuinfo \
  )
}
openssl_run_make_test() {
  make test
}
openssl_run_make_install() {
  # Don't let the install fill up on bread!
  # Software-only build.
  make install_sw
}
openssl_change_to_binary_dir() {
  cd ${OPENSSL_BINARY_DIR}
}
openssl_create_ld_library_path_script() {
  [ ! -f ./openssl.sh ] && \
  echo -e '#!/bin/sh \nenv LD_LIBRARY_PATH='"${OPENSSL_LIB_DIR} ${OPENSSL_BINARY_DIR}"'/openssl "$@"' > ./openssl.sh
}
openssl_change_ownership_of_ld_library_path_script() {
  chown root:root ./openssl.sh
}
openssl_make_ld_library_path_script_executable() {
  chmod 0755 ./openssl.sh
}
openssl_change_to_usr_bin_dir() {
  cd /usr/bin
}
openssl_create_dynamic_link_in_usr_bin() {
  ln -s ${OPENSSL_BINARY_DIR}/openssl.sh ./aes-wrap
}
openssl_confirm_app_will_run() {
  if [ $1 -gt 0 ] && [ ! -z "$( aes-wrap version -a )" ]; then
    echo -n "Confirming AES_WRAP Will Run: "

    local CHECK_STR=$( aes-wrap version -a | grep -o 'SSL' )
    [ ! -z "${CHECK_STR}" ] && \
    echo "SUCCESS!" || echo "FAILED."

    printf '%s\n' \
    "The app says:" \
    "$( aes-wrap version -a )"
  fi
}