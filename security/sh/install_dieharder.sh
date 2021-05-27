#!/bin/sh

# Name: install_dieharder.sh
# Desc: A collection of shell script functions and commands
#       that are necessary for compiling the DieHarder Test Suite.
#
# NOTE: While these scripts and commands have been authored to be
#       portable wherever possible, this effort is based on current
#       knowledge of POSIX conformance in `/bin/sh`.
#       As such, these scripts can still be improved and should not
#       be considered fully optimized for a given purpose.

check_skip_dieharder_install () {
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
}

add_dieharder_instructions_to_queue () {
  printf '%s\n' \
  apk_add_apk_tools_static \
  apk_add_busybox_static \
  apk_static_add_chrpath \
  apk_static_add_gsl \
  apk_static_add_gsl_dev \
  apk_static_add_haveged \
  apk_static_add_libtool \
  apk_static_add_make \
  apk_static_add_openrc \
  apk_static_add_rng_tools \
  apk_static_add_rpm_dev \
  apk_static_add_build_base \
  create_tmp_test_make_dir \
  change_dir_to_tmp_test_make \
  download_ent_from_fourmilab \
  extract_ent_zip_file \
  build_ent_using_make \
  move_ent_files \
  delete_ent_zip_file \
  create_home_rpmbuild_dir \
  generate_home_rpmmacros_file \
  create_dieharder_src_dir \
  change_ownership_of_dieharder_src_dir \
  export_dieharder_version_wget \
  dieharder_version_grep_version_str \
  dieharder_version_grep_version_num \
  dieharder_version_tail_last_result \
  dieharder_version_sed_remove_tgz \
  download_dieharder_latest_release \
  change_dir_to_dieharder_src \
  run_autogen_script \
  patch_line_16_dieharder_spec \
  patch_line_129_dieharder_spec \
  insert_m_pi_constant_libdieharder_h \
  insert_uint_type_def_libdieharder_h \
  compile_dieharder_using_make_install \
  display_available_random_entropy \
  EOP \
  ' '
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

dieharder_apk_add_packages() {
  # IMPORTANT: Place static tools at the start of the list.
  apk_loader $1 \
    busybox-static=1.32.1-r6 \
    apk-tools-static=2.12.5-r0 \
    build-base=0.5-r2 \
    chrpath=0.16-r2 \
    gsl-dev=2.6-r0 \
    haveged=1.9.14-r1 \
    libtool=2.4.6-r7 \
    make=4.3-r0 \
    openrc=0.42.1-r19 \
    rng-tools=6.10-r2 \
    rpm-dev=4.16.1.3-r0
}
dieharder_rc_update_add_haveged() {
  rc-update add haveged
}
dieharder_create_tmp_test_make_dir() {
  mkdir -pm 0700 /tmp/test/make
}
dieharder_change_dir_to_tmp_test_make() {
  cd /tmp/test/make
}
dieharder_download_ent_from_fourmilab() {
  wget -c http://www.fourmilab.ch/random/random.zip
}
dieharder_extract_ent_zip_file() {
  unzip random.zip
}
dieharder_build_ent_using_make() {
  make
}
dieharder_move_ent_files() {
  mv ./ent /tmp/test/  
}
dieharder_delete_ent_zip_file() {
  rm -f random.zip
}
dieharder_create_home_rpmbuild_dir() {
  mkdir -pm 0700 ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}  
}
dieharder_generate_home_rpmmacros_file() {
  echo "%_topdir %(echo $HOME)/rpmbuild" >> ~/.rpmmacros
}
dieharder_create_src_dir() {
  mkdir -pm 0700 /dieharder_src
}
dieharder_change_ownership_of_src_dir() {
  chown root:root /dieharder_src
}
dieharder_export_version_wget() {
  # Define flags for silent / verbose.
  WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of dieharder link.
  LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS http://webhome.phy.duke.edu/~rgb/General/dieharder.php \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 && return 1 ]
  # Grab version number if link is alive.
  export DIEHARDER_VERSION="$( \
    wget -c $WGET_FLAGS http://webhome.phy.duke.edu/~rgb/General/dieharder.php -O - | \
    tr -d '\n' | \
    sed "
    )"
}
dieharder_version_grep_version_str() {
  DIEHARDER_VERSION="$(echo ${DIEHARDER_VERSION} | grep -o '\"dieharder/dieharder-.*.tgz\"')"
  
}
dieharder_version_grep_version_num() {
  DIEHARDER_VERSION="$(echo ${DIEHARDER_VERSION} | grep -o '[0-9]\{1\}.[0-9]\{1,\}.[0-9]\{1,\}.tgz')"
  
}
dieharder_version_tail_last_result() {
  DIEHARDER_VERSION="$(printf '%s\n' "${DIEHARDER_VERSION}" | tail -n1)"
  
}
dieharder_version_sed_remove_tgz() {
  DIEHARDER_VERSION="$(echo ${DIEHARDER_VERSION} | sed 's/.tgz$//')"
  
}
download_dieharder_latest_release() {
  wget -c http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder-${DIEHARDER_VERSION}.tgz -O - | tar -xz -C /dieharder_src/
  
}
change_dir_to_dieharder_src() {
  cd /dieharder_src/*
  
}
run_autogen_script() {
  ./autogen.sh
  
}
patch_line_16_dieharder_spec() {
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec
  
}
patch_line_129_dieharder_spec() {
  sed -i '129s/.*/# /' ./dieharder.spec
  
}
insert_m_pi_constant_libdieharder_h() {
  sed -i '66i #define M_PI    3.14159265358979323846' ./include/dieharder/libdieharder.h
  
}
insert_uint_type_def_libdieharder_h() {
  sed -i '262i   typedef unsigned int uint;' ./include/dieharder/libdieharder.h
  
}
compile_dieharder_using_make_install() {
  
  make install
  
}
change_dir_to_tmp_test() {
  cd /tmp/test
  
}
generate_urandom_file_using_dd() {
  dd if=/dev/urandom of=/tmp/test/urandomfile bs=1 count=16384
  
}
pass_urandom_file_to_ent_no_args() {
  ./ent /tmp/test/urandomfile
  
}
pass_urandom_file_to_ent_with_args() {
  ./ent -b -c /tmp/test/urandomfile
  
}
display_available_random_entropy() {
  local AMOUNT=$(cat /proc/sys/kernel/random/entropy_avail)
  local TOTAL=$(cat /proc/sys/kernel/random/poolsize)
  local HIGH_RISK=1365
  local MED_RISK=2731
  local ALERT_LEVEL=
  if [ $AMOUNT -le $HIGH_RISK ]
  then
    ALERT_LEVEL=31
  elif [ $AMOUNT -gt $HIGH_RISK ] && [ $AMOUNT -le $MED_RISK ]
  then
    ALERT_LEVEL=33
  elif [ $AMOUNT -gt $MED_RISK ]
  then
    ALERT_LEVEL=32
  fi
  echo -e "\033[7;${ALERT_LEVEL}mRandom Entropy Avail: ${AMOUNT}\033[0m"
  echo -e "\033[7;${ALERT_LEVEL}mRandom Entropy Total: ${TOTAL}\033[0m"
}
pass_dev_random_to_rngtest() {
  
  cat /dev/random | rngtest -c 1000
  
}
rim_raf_tmp_test_dir() {
  rm -rf /tmp/test
  
}
change_dir_to_slash() {
  cd /
  
}
run_all_dieharder_tests() {
  
  dieharder -a
  
}

# NOTE:
# These Commented functions are retained for completeness where they originally appeared.
# Use of the commented functions causes catastrophic failure of DieHarder's `make install` process.
#
# patch_etc_apk_repositories() {
#   sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories
#   echo -e "\033[7;33mPatched Alpine to Latest Stable\033[0m" # These are status messages that have fg/bg commands (colors).
# }
# apk_update() {
#   apk update
#   echo -e "\033[7;33mApk Update\033[0m"
# }
# apk_static_upgrade_simulate() {
#   apk.static -U upgrade --no-self-upgrade --available --simulate
#   echo -e "\033[7;33mChecked for Problems in Alpine Upgrade\033[0m"
# }
# apk_static_upgrade() {
#   apk.static -U upgrade --no-self-upgrade --available
#   echo -e "\033[7;33mProceeded with Alpine Upgrade\033[0m"
# }
# chown_root_home_rpmbuild_dir() {
#   chown root:root $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
#   echo -e "\033[7;33mChanged Ownership of ${HOME}/rpmbuild to Root User\033[0m"
# }
# patch_line_16_dieharder_spec_in() {
#   sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec.in
#   echo -e "\033[7;33mPatched Line 16 of $(pwd)/dieharder.spec.in\033[0m"
# }
# patch_line_129_dieharder_spec_in() {
#   sed -i '129s/.*/# /' ./dieharder.spec.in
#   echo -e "\033[7;33mPathed Line 129 of $(pwd)/dieharder.spec.in\033[0m"
# }
# insert_new_line_262_libdieharder_h() {
#   sed -i '263i \ ' ./include/dieharder/libdieharder.h
#   echo -e "\033[7;33mInserted New Line 262 into $(pwd)/include/dieharder/libdieharder.h\033[0m"
# }