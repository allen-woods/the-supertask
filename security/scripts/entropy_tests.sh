#!/bin/sh

function entropy_tests {
  # Add packages needed to build ENT and DieHarder.
  apk.static add \
  chrpath \
  gsl \
  gsl-dev \
  gsl-doc \
  libtool \
  make \
  rpm-dev \
  build-base
  
  sec_header="========================================================================"

  mkdir -pm 0700 /tmp/test/make && \
  chown root:root /tmp/test/make && \
  cd /tmp/test/make
  wget http://www.fourmilab.ch/random/random.zip
  unzip random.zip
  make
  mv ./ent /tmp/test/ && cd /tmp/test
  dd if=/dev/urandom of=/tmp/test/urandomfile bs=1 count=16384

  echo "$sec_header"
  echo "Running Cryptographic Entropy Test: ENT"
  echo "  * Entropy Avail: $(cat /proc/sys/kernel/random/entropy_avail)"
  echo "  * Entropy Total: $(cat /proc/sys/kernel/random/poolsize)"
  echo "$sec_header"

  ./ent /tmp/test/urandomfile
  ./ent -b -c /tmp/test/urandomfile

  echo "$sec_header"
  echo "  Test Complete: ENT"
  echo "$sec_header"

  echo "$sec_header"
  echo "  Running Cryptographic Entropy Test: RNG-Tools"
  echo "  * Entropy Avail: $(cat /proc/sys/kernel/random/entropy_avail)"
  echo "  * Entropy Total: $(cat /proc/sys/kernel/random/poolsize)"
  echo "$sec_header"

  cat /dev/random | rngtest -c 1000
  rm -r /tmp/test/

  echo "$sec_header"
  echo "  Test Complete: RNG-TOOLS"
  echo "$sec_header"

  mkdir -pm 0700 ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  echo '%_topdir %(echo $HOME)/rpmbuild' >> ~/.rpmmacros
  mkdir -pm 0700 /dieharder_src && chown root:root /dieharder_src
  wget -c http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder-3.31.1.tgz -O - | tar -xz -C /dieharder_src/
  cd /dieharder_src/*
  ./autogen.sh
  
  # rpm -i --nodeps dieharder-3.31.1-1.src.rpm

  # Patch line 16 to fix "Failed build dependencies" error message.
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec
  sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec.in

  # Patch line 129 to fix "Macro expanded in comment" warning message.
  sed -i '129s/.*/# /' ./dieharder.spec
  sed -i '129s/.*/# /' ./dieharder.spec.in

  # Patch line 414 to fix "bufbits set but unused" error message.
  sed -i '414s/.*/ bdelta = sizeof(unsigned int)\*CHAR_BIT - bufbits;/' ./libdieharder/bits.c

  # Patch line 421 to remove `rmax_bits` where `bufbits` should be.
  sed -i '421s/.*/   printf(\"bufbits = %d  bdelta = %d\\n\",bufbits,bdelta);/' ./libdieharder/bits.c
  
  # # Insert new line 1213 to create pointer variable.
  # sed -i '1213i unsigned int \*ptr;' ./libdieharder/bits.c
  
  # # Insert new line 1216 to assign address of `tmp` to `ptr`
  # sed -i '1216i \ ptr = \&tmp;' ./libdieharder/bits.c


  # # Patch line 1217 to fix "while referencing tmp" error message.
  # sed -i '1217s/.*/ btmp = (char \*)(ptr + 2);/' ./libdieharder/bits.c

  # Errors that break build
  # File: bits.c
  # Line: 407 - "bufbits set but unused"
  #    Fix?: Changed rmax_bits to bufbits.
  # Line: 1212 - "while referencing tmp"
  #    Fix?: Added *ptr and changed &tmp to ptr.
  #    Note: This fix should resolve two remaining issues below.
  # Line: 1247 - "array subscript 8 is out of bounds (btmp[0])"
  # Line: 1265 - "array subscript 9 is out of bounds (btmp[1])"
  #
  # File: dab_dct.c
  # Line: 251 - "M_PI undeclared"
  # Line: 274 - "M_PI undeclared"
  # Line: 289 - "pos set but unused"
  #
  # File: Makefile
  # Line: 412
  # Line: 594

  make install

  # rpmbuild --rebuild dieharder-3.31.1-1.src.rpm

  # echo "$sec_header"
  # echo "Running Cryptographic Entropy Test: DieHarder"
  # echo "  * Entropy Avail: $(cat /proc/sys/kernel/random/entropy_avail)"
  # echo "  * Entropy Total: $(cat /proc/sys/kernel/random/poolsize)"
  # echo "$sec_header"

  # dieharder -a

  # echo "$sec_header"
  # echo "  Test Complete: DieHarder"
  # echo "$sec_header"
  
  # # Remove pakcages needed to build ENT and DieHarder.
  # apk.static del \
  # chrpath \
  # gsl \
  # gsl-dev \
  # gsl-doc \
  # libtool \
  # make \
  # rpm-dev \
  # build-base
}