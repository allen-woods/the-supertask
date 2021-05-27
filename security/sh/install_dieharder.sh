#!/bin/sh

# Name: install_dieharder.sh
# Desc: A collection of shell script functions and commands
#       that are necessary for compiling the DieHarder Test Suite
#       as well as ENT; a complementary entropy utility.
#
# NOTE: While these scripts and commands have been authored to be
#       portable wherever possible, this effort is based on current
#       knowledge of POSIX conformance in `/bin/sh`.
#       As such, these scripts can still be improved and should not
#       be considered fully optimized for a given purpose.

check_skip_dieharder_install () (
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
)

add_dieharder_instructions_to_queue () (
  printf '%s\n' \
  dieharder_apk_add_packages \
  dieharder_rc_update_add_haveged \
  dieharder_create_tmp_test_make_dir \
  dieharder_change_dir_to_tmp_test_make \
  dieharder_download_ent_from_fourmilab \
  dieharder_extract_ent_zip_file \
  dieharder_build_ent_using_make \
  dieharder_move_ent_files \
  dieharder_delete_ent_zip_file \
  dieharder_create_home_rpmbuild_dir \
  dieharder_generate_home_rpmmacros_file \
  dieharder_create_src_dir \
  dieharder_change_ownership_of_src_dir \
  dieharder_export_version_wget \
  dieharder_download_latest_release \
  dieharder_change_to_src_dir \
  dieharder_run_autogen \
  dieharder_patch_spec_line_16 \
  dieharder_patch_spec_line_129 \
  dieharder_insert_m_pi_constant \
  dieharder_insert_uint_type_def \
  dieharder_compile_using_make_install \
  dieharder_change_to_tmp_test_dir \
  dieharder_generate_urandom_file_using_dd \
  dieharder_pass_urandom_file_to_ent_no_args \
  dieharder_pass_urandom_file_to_ent_with_args \
  dieharder_display_available_random_entropy \
  dieharder_pass_dev_random_to_rngtest \
  dieharder_rim_raf_tmp_test_dir \
  dieharder_change_to_slash_dir \
  dieharder_run_all_tests \
  EOP \
  ' ' 1>&3
)

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

dieharder_apk_add_packages () (
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
)
dieharder_rc_update_add_haveged () (
  rc-update add haveged
)
dieharder_create_tmp_test_make_dir () (
  mkdir -pm 0700 /tmp/test/make
)
dieharder_change_dir_to_tmp_test_make () (
  cd /tmp/test/make
)
dieharder_download_ent_from_fourmilab () (
  # Define flags for silent / verbose.
  WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of ENT link.
  LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS http://www.fourmilab.ch/random/random.zip \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Download if link is alive.
  wget -c $WGET_FLAGS http://www.fourmilab.ch/random/random.zip
)
dieharder_extract_ent_zip_file () (
  unzip random.zip
)
dieharder_build_ent_using_make () (
  make
)
dieharder_move_ent_files () (
  mv ./ent /tmp/test/  
)
dieharder_delete_ent_zip_file () (
  rm -f random.zip
)
dieharder_create_home_rpmbuild_dir () (
  mkdir -pm 0700 ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}  
)
dieharder_generate_home_rpmmacros_file () (
  echo "%_topdir %(echo $HOME)/rpmbuild" >> ~/.rpmmacros
)
dieharder_create_src_dir () (
  mkdir -pm 0700 /dieharder_src
)
dieharder_change_ownership_of_src_dir () (
  chown root:root /dieharder_src
)
dieharder_export_version_wget () (
  # Define flags for silent / verbose.
  WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of dieharder link.
  LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS http://webhome.phy.duke.edu/~rgb/General/dieharder.php \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Grab version number if link is alive.
  export DIEHARDER_VERSION=$( \
    wget -c $WGET_FLAGS http://webhome.phy.duke.edu/~rgb/General/dieharder.php -O - | \
    tr -d '\n' | \
    sed "s|^.*\"\(dieharder/dieharder-[0-9]\{1\}.[0-9]\{1,\}.[0-9]\{1,\}\).tgz\".*$|\1|g" \
  )
)
dieharder_download_latest_release () (
  # Define flags used for silent / verbose.
  WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of archive link.
  LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS http://webhome.phy.duke.edu/~rgb/General/${DIEHARDER_VERSION}.tgz \
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Download version is link is alive.
  wget -c http://webhome.phy.duke.edu/~rgb/General/${DIEHARDER_VERSION}.tgz -O - | \
  tar -xz -C /dieharder_src/
)
dieharder_change_to_src_dir () (
  cd /dieharder_src/*
)
dieharder_run_autogen () (
  ./autogen.sh
)
dieharder_patch_spec_line_16 () (
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec
)
dieharder_patch_spec_line_129 () (
  sed -i '129s/.*/# /' ./dieharder.spec
)
dieharder_insert_m_pi_constant () (
  sed -i '66i #define M_PI    3.14159265358979323846' ./include/dieharder/libdieharder.h
)
dieharder_insert_uint_type_def () (
  sed -i '262i   typedef unsigned int uint;' ./include/dieharder/libdieharder.h
)
dieharder_compile_using_make_install () (
  make install
)
dieharder_change_to_tmp_test_dir () (
  cd /tmp/test
)
dieharder_generate_urandom_file_using_dd () (
  dd if=/dev/urandom of=/tmp/test/urandomfile bs=1 count=16384
)
dieharder_pass_urandom_file_to_ent_no_args () (
  ./ent /tmp/test/urandomfile
)
dieharder_pass_urandom_file_to_ent_with_args () (
  ./ent -b -c /tmp/test/urandomfile
)
dieharder_display_available_random_entropy () (
  AMOUNT=$(cat /proc/sys/kernel/random/entropy_avail)
  TOTAL=$(cat /proc/sys/kernel/random/poolsize)
  HIGH_RISK=1365
  MED_RISK=2731
  
  if [ $AMOUNT -le $HIGH_RISK ]
  then
    ALERT_LEVEL=31
  elif [[ $AMOUNT -gt $HIGH_RISK && $AMOUNT -le $MED_RISK ]]
  then
    ALERT_LEVEL=33
  elif [ $AMOUNT -gt $MED_RISK ]
  then
    ALERT_LEVEL=32
  fi
  [ $1 -gt 0 ] && echo -e "\033[7;${ALERT_LEVEL}mRandom Entropy Avail: ${AMOUNT}\033[0m"
  [ $1 -gt 0 ] && echo -e "\033[7;${ALERT_LEVEL}mRandom Entropy Total: ${TOTAL}\033[0m"
)
dieharder_pass_dev_random_to_rngtest () (
  cat /dev/random | rngtest -c 1000
)
dieharder_rim_raf_tmp_test_dir () (
  rm -rf /tmp/test  
)
dieharder_change_to_slash_dir () (
  cd /
)
dieharder_run_all_tests () (
  dieharder -a
)