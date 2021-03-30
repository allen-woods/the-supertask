#!/bin/sh

# NAME: install_openssl.sh
# DESC: A script containing instructions for generating an AES wrap-enabled build of the latest release of OpenSSL.

export OPENSSL_HOME_PATH="${HOME}"
export OPENSSL_HOME_BUILD_PATH="${OPENSSL_HOME_PATH}/build"
export OPENSSL_HOME_LOCAL_PATH="${OPENSSL_HOME_PATH}/local"
export OPENSSL_HOME_LOCAL_BIN_PATH="${OPENSSL_HOME_PATH}/local/bin"
export OPENSSL_HOME_LOCAL_SSL_PATH="${OPENSSL_HOME_PATH}/local/ssl"
export OPENSSL_HOME_LOCAL_LIB_PATH="${OPENSSL_HOME_PATH}/local/lib"

check_skip_openssl_install() {
  if [ -d $OPENSSL_HOME_BUILD_PATH ] && \
    [ -d $OPENSSL_HOME_LOCAL_PATH ] && \
    [ -d $OPENSSL_HOME_LOCAL_BIN_PATH ] && \
    [ -d $OPENSSL_HOME_LOCAL_SSL_PATH ] && \
    [ -f "${OPENSSL_HOME_LOCAL_BIN_PATH}/openssl.sh" ]; then
    echo -n "SKIP"
  else
    echo -n "INSTALL"
  fi
}

add_openssl_instructions_to_queue() {
  printf '%s\n' \
  openssl_apk_add_packages \
  openssl_create_home_build_dir \
  openssl_create_home_local_ssl_dir \
  openssl_export_openssl_source_version_wget \
  openssl_change_to_home_build_dir \
  openssl_download_openssl_source_version \
  openssl_extract_openssl_source_version_tar \
  openssl_remove_openssl_source_version_tar \
  openssl_enable_aes_wrapping_in_openssl \
  openssl_change_to_home_build_openssl_version_dir \
  openssl_config_openssl_version_build \
  openssl_make_j_grep_openssl_version_build \
  openssl_make_install_openssl_version_build \
  openssl_create_openssl_shell_script \
  openssl_shrc_file_for_openssl_v111_env_var \
  openssl_verify_openssl_version \
  openssl_remove_unnecessary_packages \
  EOP \
  ' ' 1>&3
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

openssl_apk_add_packages() {
  apk --no-cache add \
    busybox-static \
    apk-tools-static && \
  apk.static add \
    build-base \
    dumb-init \
    gnupg \
    linux-headers \
    outils-jot \
    perl \
    pinentry-gtk
  # NOTE: this script only runs during docker build,
  #       so we can't run `pretty` to echo nicely.
  echo -e "\033[7;33mAdded Packages using APK\033[0m"
}
openssl_create_home_build_dir() {
  [ ! -d $OPENSSL_HOME_BUILD_PATH ] && mkdir $OPENSSL_HOME_BUILD_PATH 1>&4
  echo -e "\033[7;33mCreated Directory: ${OPENSSL_HOME_BUILD_PATH}\033[0m" 1>&5
}
openssl_create_home_local_ssl_dir() {
  [ ! -d $OPENSSL_HOME_LOCAL_SSL_PATH ] && mkdir -p $OPENSSL_HOME_LOCAL_SSL_PATH 1>&4
  echo -e "\033[7;33mCreated Directory: ${OPENSSL_HOME_LOCAL_SSL_PATH}\033[0m" 1>&5
}
openssl_export_openssl_source_version_wget() {
  export OPENSSL_SOURCE_VERSION="$(echo \
    $(wget -c https://www.openssl.org/source/index.html -O -) | \
    sed 's/^.*\"\(openssl[-]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[.]\{1\}[0-9]\{1,\}[a-zA-Z]\{0,\}\).tar.gz\".*$/\1/g; s/^.* \([^ ]\{1,\}\)$/\1/g;' \
  )" 1>&4
  echo -e "\033[7;33mParsed OpenSSL Version to Variable Using WGET and SED\033[0m" 1>&5
}
openssl_change_to_home_build_dir() {
  cd ${OPENSSL_HOME_BUILD_PATH} 1>&4
  echo -e "\033[7;33mChanged Current Directory to: ${OPENSSL_HOME_BUILD_PATH}\033[0m" 1>&5
}
openssl_download_openssl_source_version() {
  wget -c https://openssl.org/source/${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mDownloaded Source TAR for Latest Stable OpenSSL\033[0m" 1>&5
}
openssl_extract_openssl_source_version_tar() {
  tar -xzf ${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mExtracted Source TAR for Latest Stable OpenSSL\033[0m" 1>&5
}
openssl_remove_openssl_source_version_tar() {
  rm -f ${OPENSSL_SOURCE_VERSION}.tar.gz 1>&4
  echo -e "\033[7;33mForced Removal of Source TAR File\033[0m" 1>&5
}
openssl_enable_aes_wrapping_in_openssl() {
  sed -i 's/\(.*\)BIO_get_cipher_ctx(benc, \&ctx);/\1BIO_get_cipher_ctx(benc, \&ctx);\n\1EVP_CIPHER_CTX_set_flags(ctx, EVP_CIPHER_CTX_FLAG_WRAP_ALLOW);/g' ./${OPENSSL_SOURCE_VERSION}/apps/enc.c 1>&4
  echo -e "\033[7;33mPatched OpenSSL to Enable AES Wrapping\033[0m" 1>&5
}
openssl_change_to_home_build_openssl_version_dir() {
  cd ./${OPENSSL_SOURCE_VERSION} 1>&4
  echo -e "\033[7;33mChanged Current Directory to /root/build/${OPENSSL_SOURCE_VERSION}\033[0m" 1>&5
}
openssl_config_openssl_version_build() {
  ./config --prefix=${OPENSSL_HOME_LOCAL_PATH} --openssldir=${OPENSSL_HOME_LOCAL_SSL_PATH} 1>&4
  echo -e "\033[7;33mConfigured Build of OpenSSL\033[0m" 1>&5
}
openssl_make_j_grep_openssl_version_build() {
  make -j$(grep -c ^processor /proc/cpuinfo) 1>&4
  echo -e "\033[7;33mRan Make With -j Option\033[0m" 1>&5
}
openssl_make_install_openssl_version_build() {
  make install_sw 1>&4
  echo -e "\033[7;33mRan Make install_sw to Build OpenSSL (Software Only)\033[0m" 1>&5
}
openssl_make_clean_openssl_version_build() {
  make clean 1>&4
  echo -e "\033[7;33mRan Make clean to Remove Build Files\033[0m" 1>&5
}
openssl_create_openssl_shell_script() {
  echo -e '#!/bin/sh \nenv LD_LIBRARY_PATH='"${OPENSSL_HOME_LOCAL_LIB_PATH} ${OPENSSL_HOME_LOCAL_BIN_PATH}/openssl"' "$@"' > ${OPENSSL_HOME_LOCAL_BIN_PATH}/openssl.sh
  chmod 0755 ${OPENSSL_HOME_LOCAL_BIN_PATH}/openssl.sh 1>&4
  chown root:root ${OPENSSL_HOME_LOCAL_BIN_PATH}/openssl.sh 1>&4
  echo -e "\033[7;33mCreated Shell Script for Running OpenSSL\033[0m" 1>&5
}
openssl_shrc_file_for_openssl_v111_env_var() {
  echo "export OPENSSL_V111=${OPENSSL_HOME_LOCAL_BIN_PATH}/openssl.sh" > "${OPENSSL_HOME_PATH}/.shrc"
  echo -e "\033[7;33mGenerated SHRC File for Export of OPENSSL_V111 Env Var\033[0m" 1>&5
}
openssl_verify_openssl_version() {
  local OUTPUT_MSG="Verified OpenSSL Version"
  . ${OPENSSL_HOME_PATH}/.shrc 1>&4
  local VERIFIED="$($OPENSSL_V111 version 2>&1)"
  # TODO: Uncomment and implement this block of code to conditionally report errors, if any.
  # local RETURN_ONE=0
  # if [ -z "${VERIFIED}" ] || [ "$(echo "${VERIFIED}" | sed 's/^.*\(not found\)$/\1/g')" == "not found" ]; then
  #   OUTPUT_MSG="ERROR: Unable to Verify OpenSSL Version"
  #   RETURN_ONE=1
  # fi
  # echo -e "\033[7;33m${OUTPUT_MSG}\033[0m" 1>&5
  # [ $RETURN_ONE -eq 1 ] && return 1 # Tell further instructions to abort, the failure of this one is critical.
  echo ""
  echo -ne "OPENSSL_V111 printed: \n${VERIFIED}"
  echo ""
}
openssl_remove_unnecessary_packages() {
  apk.static del \
    build-base \
    dumb-init \
    gnupg \
    linux-headers \
    outils-jot \
    perl \
    pinentry-gtk && \
  apk del \
    busybox-static \
    apk-tools-static
  echo -e "\033[7;33mRemoved Un-necessary Packages\033[0m"
}