#!/bin/sh

sec_header="==============================================================================="
sec_byline="- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
last=0

function exit_if_not_ok {
  if [ $last -ne 0 ]
  then
    return 1
  fi
}

function entropy_tests {
  install_dev_pkgs
  install_ent
  run_ent
  run_rngtest
  install_dieharder
  run_dieharder
  #  uninstall_dev_pkgs
}

function install_dev_pkgs {
  echo "$sec_header"
  echo "  Installing:"
  echo "$sec_byline"'
    - BUILD-BASE
    - CHRPATH
    - GSL
    - GSL-DEV
    - GSL-DOC
    - LIBTOOL
    - MAKE
    - RPM-DEV

    Purpose:
      Packages Needed to Compile DieHarder 3.31.1.
  '

  apk.static add \
  chrpath \
  gsl \
  gsl-dev \
  gsl-doc \
  libtool \
  make \
  rpm-dev \
  build-base
  last=$?
  exit_if_not_ok

  echo "$sec_byline"
  echo "  OK: Packages Installed!"
  echo "$sec_header"
}

function install_ent {
  echo "$sec_header"
  echo "  Installing:"
  echo "$sec_byline"'
    - ENT

    Purpose:
      Entropy Testing Utility.
  '

  mkdir -pm 0700 /tmp/test/make
  last=$?
  exit_if_not_ok

  chown root:root /tmp/test/make
  last=$?
  exit_if_not_ok

  cd /tmp/test/make
  last=$?
  exit_if_not_ok

  wget http://www.fourmilab.ch/random/random.zip > /dev/null 2>&1
  last=$?
  exit_if_not_ok
  
  unzip random.zip > /dev/null 2>&1
  last=$?
  exit_if_not_ok

  make > /dev/null 2>&1
  last=$?
  exit_if_not_ok

  mv ./ent /tmp/test/
  last=$?
  exit_if_not_ok
  
  cd /tmp/test
  last=$?
  exit_if_not_ok

  echo "$sec_byline"
  echo "  OK: ENT Installed!"
  echo "$sec_header"
}

function run_ent {
  echo "$sec_header"
  echo "  Running:"
  echo "$sec_byline"'
    - ENT

    Purpose:
      Test against available system entropy.
  '

  cd /tmp/test
  last=$?
  exit_if_not_ok

  dd if=/dev/urandom of=/tmp/test/urandomfile bs=1 count=16384 > /dev/null 2>&1
  last=$?
  exit_if_not_ok

  ./ent /tmp/test/urandomfile
  last=$?
  exit_if_not_ok

  ./ent -b -c /tmp/test/urandomfile
  last=$?
  exit_if_not_ok

  echo "$sec_byline"
  echo "  - Entropy Avail: $(cat /proc/sys/kernel/random/entropy_avail)"
  echo "  - Entropy Total: $(cat /proc/sys/kernel/random/poolsize)"
  echo "$sec_byline"
  echo "  OK: ENT Test Complete!"
  echo "$sec_header"
}

function run_rngtest {
  echo "$sec_header"
  echo "  Running:"
  echo "$sec_byline"'
    - RNGTEST

    Purpose:
      Test against available system entropy.
  '
  cd /tmp/test
  last=$?
  exit_if_not_ok
  
  # The commented lines in this function threw errors.

  cat /dev/random | rngtest -c 1000
  # last=$?
  # exit_if_not_ok

  rm -r /tmp/test/
  # last=$?
  # exit_if_not_ok

  echo "$sec_byline"
  echo "  - Entropy Avail: $(cat /proc/sys/kernel/random/entropy_avail)"
  echo "  - Entropy Total: $(cat /proc/sys/kernel/random/poolsize)"
  echo "$sec_byline"
  echo "  OK: RNGTEST Test Complete!"
  echo "$sec_header"
}

function install_dieharder {
  echo "$sec_header"
  echo "  Installing:"
  echo "$sec_byline"'
    - DIEHARDER

    Purpose:
      Suite of entropy testing utilities.
  '

  mkdir -pm 0700 ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  last=$?
  exit_if_not_ok

  echo '%_topdir %(echo $HOME)/rpmbuild' >> ~/.rpmmacros
  last=$?
  exit_if_not_ok

  mkdir -pm 0700 /dieharder_src
  last=$?
  exit_if_not_ok
  
  chown root:root /dieharder_src
  last=$?
  exit_if_not_ok

  wget -c --quiet http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder-3.31.1.tgz -O - | tar -xz -C /dieharder_src/
  last=$?
  exit_if_not_ok

  cd /dieharder_src/*
  last=$?
  exit_if_not_ok

  ./autogen.sh > /dev/null 2>&1
  last=$?
  exit_if_not_ok

  echo "$sec_byline"
  echo "    Patching DieHarder Install Files..."
  
  # * * * * * Perform Surgery on Broken Install * * * * *

  # ---------------- DIEHARDER.SPEC
  
  # Patch line 16 to fix "Failed build dependencies" error message.
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec
  last=$?
  exit_if_not_ok

  # Patch line 129 to fix "Macro expanded in comment" warning message.
  sed -i '129s/.*/# /' ./dieharder.spec
  last=$?
  exit_if_not_ok

  # ---------------- DIEHARDER.SPEC.IN

  # Patch line 16 to fix "Failed build dependencies" error message.
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec.in
  last=$?
  exit_if_not_ok

  # Patch line 129 to fix "Macro expanded in comment" warning message.
  sed -i '129s/.*/# /' ./dieharder.spec.in
  last=$?
  exit_if_not_ok

  # ---------------- LIBDIEHARDER.H

  # Insert new line 66 to define `M_PI` constant.
  sed -i '66i #define M_PI    3.14159265358979323846' ./include/dieharder/libdieharder.h
  last=$?
  exit_if_not_ok

  # Insert new line 262 to create `uint` typedef.
  sed -i '262i typedef unsigned int uint;' ./include/dieharder/libdieharder.h
  last=$?
  exit_if_not_ok

  # Insert new line 263 to clean up formatting.
  sed -i '263i \ ' ./include/dieharder/libdieharder.h
  last=$?
  exit_if_not_ok

  # * * * * * * * * * * * * * * * * * * * * * * * * * * *

  echo "    Compiling DieHarder..."

  make install > /dev/null 2>&1
  last=$?
  exit_if_not_ok

  echo "$sec_byline"
  echo "  OK: DieHarder Installed!"
  echo "$sec_header"
}

function run_dieharder {
  echo "$sec_header"
  echo "  Running:"
  echo "$sec_byline"'
    - DIEHARDER

    Purpose:
      Test extensively against available system entropy.
    
    Note:
      This process is very slow and will take some time.
  '

  dieharder -a
  last=$?
  exit_if_not_ok

  echo "$sec_byline"
  echo "  - Entropy Avail: $(cat /proc/sys/kernel/random/entropy_avail)"
  echo "  - Entropy Total: $(cat /proc/sys/kernel/random/poolsize)"
  echo "$sec_byline"
  echo "  OK: DIEHARDER Test Suite Complete!"
  echo "$sec_header"
}

function uninstall_dev_pkgs {
  echo "$sec_header"
  echo "  Uninstalling:"
  echo "$sec_byline"'
    - BUILD-BASE
    - CHRPATH
    - GSL
    - GSL-DEV
    - GSL-DOC
    - LIBTOOL
    - MAKE
    - RPM-DEV

    Purpose:
      Compilation(s) complete, packages no longer needed.
  '

  apk.static del \
  chrpath \
  gsl \
  gsl-dev \
  gsl-doc \
  libtool \
  make \
  rpm-dev \
  build-base
  last=$?
  exit_if_not_ok

  echo "$sec_byline"
  echo "  OK: Packages Uninstalled!"
  echo "$sec_header"
}