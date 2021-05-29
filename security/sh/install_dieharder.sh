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

check_skip_dieharder_install () (
  # TODO: Steps required to confirm already installed go here.
  echo -n "OK"
)

add_dieharder_instructions_to_queue () (
  printf '%s\n' \
  dieharder_apk_add_packages \
  dieharder_rc_update_add_haveged \
  dieharder_create_src_dir \
  dieharder_change_ownership_of_src_dir \
  dieharder_export_version_wget \
  dieharder_download_latest_release \
  dieharder_change_to_src_dir \
  dieharder_download_config_guess \
  dieharder_download_config_sub \
  dieharder_run_autogen \
  dieharder_patch_spec_line_16 \
  dieharder_patch_spec_line_129 \
  dieharder_insert_m_pi_constant \
  dieharder_insert_uint_type_def \
  dieharder_compile_using_make_install \
  dieharder_rim_raf_src_dir \
  EOP \
  ' ' 1>&3
)

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *

dieharder_apk_add_packages () (
  # IMPORTANT: Place static tools at the start of the list.
  apk_loader $1 \
    busybox-static=1.31.1-r20 \
    apk-tools-static=2.10.6-r0 \
    build-base=0.5-r2 \
    chrpath=0.16-r2 \
    gsl-dev=2.6-r0 \
    haveged=1.9.8-r1 \
    libtool=2.4.6-r7 \
    make=4.3-r0 \
    openrc=0.42.1-r11\
    rng-tools=6.10-r2 \
    rpm-dev=4.15.1-r2
)
dieharder_rc_update_add_haveged () (
  rc-update add haveged
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
  # Download version if link is alive.
  wget -c http://webhome.phy.duke.edu/~rgb/General/${DIEHARDER_VERSION}.tgz -O - | \
  tar -xz -C /dieharder_src/
)
dieharder_change_to_src_dir () (
  cd /dieharder_src/*
)
dieharder_download_config_guess () (
  # Define flags used for silent / verbose.
  WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of file link.
  LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.guess
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Download file if link is alive.
  wget -c http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.guess
)
dieharder_download_config_sub () (
  # Define flags used for silent / verbose.
  WGET_FLAGS=
  [ $1 -eq 0 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-q'
  [ $1 -eq 2 ] && [ -z "${WGET_FLAGS}" ] && WGET_FLAGS='-S'
  # Check health of file link.
  LINK_ALIVE=$( \
    wget --spider $WGET_FLAGS http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.sub
  )
  # Conditionally halt if link is dead.
  [ $? -gt 1 ] && return 1
  # Download file if link is alive.
  wget -c http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.sub
)
dieharder_run_autogen () (
  ./autogen.sh
)
dieharder_patch_spec_line_16 () (
  sed -i '16s|devel|dev|' ./dieharder.spec
)
dieharder_patch_spec_line_129 () (
  sed -i '129s|.*|# |' ./dieharder.spec
)
dieharder_insert_m_pi_constant () (
  sed -i '66i #define M_PI    3.141592653589793238462643' ./include/dieharder/libdieharder.h
)
dieharder_insert_uint_type_def () (
  sed -i '262i   typedef unsigned int uint;' ./include/dieharder/libdieharder.h
)
dieharder_compile_using_make_install () (
  make install
)
dieharder_rim_raf_src_dir () (
  rm -rf /dieharder_src
)