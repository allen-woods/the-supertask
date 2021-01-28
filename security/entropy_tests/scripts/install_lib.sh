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
  patch_etc_apk_repositories \
  apk_update \
  apk_add_busybox_static \
  apk_add_apk_tools_static \
  apk_static_upgrade_simulate \
  apk_static_upgrade \
  apk_static_add_build_base \
  apk_static_add_chrpath \
  apk_static_add_gsl \
  apk_static_add_gsl_dev \
  apk_static_add_haveged \
  apk_static_add_libtool \
  apk_static_add_openrc \
  apk_static_add_rng_tools \
  apk_static_add_rpm_dev \
  create_tmp_test_make_dir \
  change_dir_to_tmp_test_make \
  download_ent_from_fourmilab \
  extract_ent_zip_file \
  build_ent_using_make \
  move_ent_files \
  delete_ent_zip_file \
  create_home_rpmbuild_dir \
  chown_root_home_rpmbuild_dir \
  generate_home_rpmmacros_file \
  create_dieharder_src_dir \
  chown_root_dieharder_src_dir \
  download_dieharder_latest_release \
  change_dir_to_dieharder_src \
  run_autogen_script \
  patch_line_16_dieharder_spec \
  patch_line_129_dieharder_spec \
  patch_line_16_dieharder_spec_in \
  patch_line_129_dieharder_spec_in \
  insert_m_pi_constant_libdieharder_h \
  insert_uint_type_def_libdieharder_h \
  insert_new_line_262_libdieharder_h \
  compile_dieharder_using_make_install \
  change_dir_to_tmp_test \
  generate_urandom_file_using_dd \
  pass_urandom_file_to_ent_no_args \
  pass_urandom_file_to_ent_with_args \
  display_available_random_entropy \
  change_dir_to_tmp_test \
  pass_dev_random_to_rngtest \
  rim_raf_tmp_test_dir \
  display_available_random_entropy \
  change_dir_to_slash \
  run_all_dieharder_tests \
  display_available_random_entropy \
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
apk_static_add_chrpath() {
  apk.static add chrpath 1>&4
  echo -e "\033[7;33mAdded Chrpath\033[0m" 1>&5
}
apk_static_add_gsl() {
  apk.static add gsl 1>&4
  echo -e "\033[7;33mAdded Gsl\033[0m" 1>&5
}
apk_static_add_gsl_dev() {
  apk.static add gsl-dev 1>&4
  echo -e "\033[7;33mAdded Gsl Dev\033[0m" 1>&5
}
apk_static_add_haveged() {
  apk.static add haveged 1>&4
  echo -e "\033[7;33mAdded Haveged\033[0m" 1>&5
}
apk_static_add_libtool() {
  apk.static add libtool 1>&4
  echo -e "\033[7;33mAdded Libtool\033[0m" 1>&5
}
apk_static_add_openrc() {
  apk.static add openrc 1>&4
  echo -e "\033[7;33mAdded OpenRC\033[0m" 1>&5
}
apk_static_add_rng_tools() {
  apk.static add rng-tools 1>&4
  echo -e "\033[7;33mAdded RNG Tools\033[0m" 1>&5
}
apk_static_add_rpm_dev() {
  apk.static add rpm-dev 1>&4
  echo -e "\033[7;33mAdded RPM Dev\033[0m" 1>&5
}
rc_update_add_haveged() {
  rc-update add haveged 1>&4
  echo -e "\033[7;33mScheduled Haveged Using rc-update\033[0m" 1>&5
}
create_tmp_test_make_dir() {
  mkdir -pm 0700 /tmp/test/make 1>&4
  echo -e "\033[7;33mCreated /tmp/test/make Directory\033[0m" 1>&5
}
change_dir_to_tmp_test_make() {
  cd /tmp/test/make 1>&4
  echo -e "\033[7;33mChanged Current Directory to /tmp/test/make\033[0m" 1>&5
}
download_ent_from_fourmilab() {
  wget http://www.fourmilab.ch/random/random.zip 1>&4
  echo -e "\033[7;33mDownloaded ENT from FourmiLab\033[0m" 1>&5
}
extract_ent_zip_file() {
  unzip random.zip 1>&4
  echo -e "\033[7;33mExtracted ENT Zip Archive\033[0m" 1>&5
}
build_ent_using_make() {
  make 1>&4
  echo -e "\033[7;33mRan Make to Build ENT\033[0m" 1>&5
}
move_ent_files() {
  mv ./ent /tmp/test/ 1>&4
  echo -e "\033[7;33mMoved ENT Files from $(pwd)/ent to /tmp/test\033[0m" 1>&5
}
delete_ent_zip_file() {
  rm -f random.zip 1>&4
  echo -e "\033[7;33mDeleted ENT Zip Archive\033[0m" 1>&5
}
create_home_rpmbuild_dir() {
  mkdir -pm 0700 $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} 1>&4
  echo -e "\033[7;33mCreated ${HOME}/rpmbuild Directory\033[0m" 1>&5
}
chown_root_home_rpmbuild_dir() {
  chown root:root $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} 1>&4
  echo -e "\033[7;33mChanged Ownership of ${HOME}/rpmbuild to Root User\033[0m" 1>&5
}
generate_home_rpmmacros_file() {
  echo '%_topdir %(echo $HOME)/rpmbuild' >> $HOME/.rpmmacros 1>&4
  echo -e "\033[7;33mGenerated ${HOME}/.rpmmacros File\033[0m" 1>&5
}
create_dieharder_src_dir() {
  mkdir -pm 0700 /dieharder_src 1>&4
  echo -e "\033[7;33mCreated /dieharder_src Directory\033[0m" 1>&5
}
chown_root_dieharder_src_dir() {
  chown root:root /dieharder_src 1>&4
  echo -e "\033[7;33mChanged Ownership of /dieharder_src to Root User\033[0m" 1>&5
}
download_dieharder_latest_release() {
  wget -c http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder.tgz -O - | tar -xz -C /dieharder_src/ 1>&4
  echo -e "\033[7;33mDownloaded Latest Release of DieHarder to /dieharder_src\033[0m" 1>&5
}
change_dir_to_dieharder_src() {
  cd /dieharder_src/* 1>&4
  echo -e "\033[7;33mChanged Current Directory to $(pwd)\033[0m" 1>&5
}
run_autogen_script() {
  ./autogen.sh 1>&4
  echo -e "\033[7;33mRan Autogen Script\033[0m" 1>&5
}
patch_line_16_dieharder_spec() {
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec 1>&4
  echo -e "\033[7;33mPatched Line 16 of $(pwd)/dieharder.spec\033[0m" 1>&5
}
patch_line_129_dieharder_spec() {
  sed -i '129s/.*/# /' ./dieharder.spec 1>&4
  echo -e "\033[7;33mPathed Line 129 of $(pwd)/dieharder.spec\033[0m" 1>&5
}
patch_line_16_dieharder_spec_in() {
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec.in 1>&4
  echo -e "\033[7;33mPatched Line 16 of $(pwd)/dieharder.spec.in\033[0m" 1>&5
}
patch_line_129_dieharder_spec_in() {
  sed -i '129s/.*/# /' ./dieharder.spec.in 1>&4
  echo -e "\033[7;33mPathed Line 129 of $(pwd)/dieharder.spec.in\033[0m" 1>&5
}
insert_m_pi_constant_libdieharder_h() {
  sed -i '66i #define M_PI    3.14159265358979323846' ./include/dieharder/libdieharder.h 1>&4
  echo -e "\033[7;33mInserted Missing Constant M_PI into $(pwd)/include/dieharder/libdieharder.h\033[0m" 1>&5
}
insert_uint_type_def_libdieharder_h() {
  sed -i '262i typedef unsigned int uint;' ./include/dieharder/libdieharder.h 1>&4
  echo -e "\033[7;33mInserted Missing uint Type Definition into $(pwd)/include/dieharder/libdieharder.h\033[0m" 1>&5
}
insert_new_line_262_libdieharder_h() {
  sed -i '263i \ ' ./include/dieharder/libdieharder.h 1>&4
  echo -e "\033[7;33mInserted New Line 262 into $(pwd)/include/dieharder/libdieharder.h\033[0m" 1>&5
}
compile_dieharder_using_make_install() {
  echo -e "\033[7;33mCompiling DieHarder Test Suite. Please Wait..." 1>&5
  make install 1>&4
  echo -e "\033[7;33mRan Make to Build Installation of DieHarder Test Suite\033[0m" 1>&5
}
change_dir_to_tmp_test() {
  cd /tmp/test 1>&4
  echo -e "\033[7;33mChanged Current Directory to /tmp/test\033[0m" 1>&5
}
generate_urandom_file_using_dd() {
  dd if=/dev/urandom of=/tmp/test/urandomfile bs=1 count=16384 1>&4
  echo -e "\033[7;33mGenerated Urandom File Using DD\033[0m" 1>&5
}
pass_urandom_file_to_ent_no_args() {
  ./ent /tmp/test/urandomfile 1>&4
  echo -e "\033[7;33mPassed Urandom File to ENT Without Arguments\033[0m" 1>&5
}
pass_urandom_file_to_ent_with_args() {
  ./ent -b -c /tmp/test/urandomfile 1>&4
  echo -e "\033[7;33mPassed Urandom File to ENT With Arguments -b -c\033[0m" 1>&5
}
display_available_random_entropy() {
  local AMOUNT=$(cat /proc/sys/kernel/random/entropy_avail)
  local TOTAL=$(cat /proc/sys/kernal/random/poolsize)
  local RATIO=$(($AMOUNT / $TOTAL))
  local HIGH_RISK=$((1 / 3))
  local MED_RISK=$((2 / 3))
  local ALERT_LEVEL=
  if [ $RATIO -le $HIGH_RISK ]
  then
    ALERT_LEVEL=31
  elif [ $RATIO -gt $HIGH_RISK ] && [ $RATIO -le $MED_RISK ]
  then
    ALERT_LEVEL=33
  elif [ $RATIO -gt $MED_RISK ]
  then
    ALERT_LEVEL=32
  fi
  echo -e "\033[7;${ALERT_LEVEL}mRandom Entropy Avail: ${AMOUNT}\033[0m" 1>&5
  echo -e "\033[7;${ALERT_LEVEL}mRandom Entropy Total: ${TOTAL}\033[0m" 1>&5
}
pass_dev_random_to_rngtest() {
  cat /dev/random | rngtest -c 100000 1>&4
  echo -e "\033[7;33mPassed Dev Random to RNG-TEST\033[0m" 1>&5
}
rim_raf_tmp_test_dir() {
  rm -rf /tmp/test 1>&4
  echo -e "\033[7;33mRecursively Deleted /tmp/test Diretory\033[0m" 1>&5
}
change_dir_to_slash() {
  cd / 1>&4
  echo -e "\033[7;33mChanged Current Directory to /\033[0m"
}
run_all_dieharder_tests() {
  echo -e "\033[7;33mPreparing to Run DieHarder. Please Wait..." 1>&5
  dieharder - a 1>&4
  echo -e "\033[7;33mSuessfully Ran Entire DieHarder Test Suite\033[0m" 1>&5
}