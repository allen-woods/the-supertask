#!/bin/sh

cmd_01() { apk.static add build-base
}
cmd_02() { apk.static add chrpath
}
cmd_03() { apk.static add gsl
}
cmd_04() { apk.static add gsl-dev
}
cmd_05() { apk.static add haveged
}
cmd_06() { apk.static add libtool
}
cmd_07() { apk.static add openrc
}
cmd_08() { apk.static add rng-tools
}
cmd_09() { apk.static add rpm-dev
}
cmd_10() { rc-update add haveged
}
cmd_11() { mkdir -pm 0700 /tmp/test/make
}
cmd_12() { cd /tmp/test/make
}
cmd_13() { wget http://www.fourmilab.ch/random/random.zip
}
cmd_14() { unzip random.zip
}
cmd_15() { make
}
cmd_16() { mv ./ent /tmp/test/
}
cmd_17() { rm -f random.zip
}
cmd_18() { mkdir -pm 0700 ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
}
cmd_19() { chown root:root ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
}
cmd_20() { echo '%_topdir %(echo $HOME)/rpmbuild' >> ~/.rpmmacros
}
cmd_21() { mkdir -pm 0700 /dieharder_src
}
cmd_22() { chown root:root /dieharder_src
}
cmd_23() { wget -c --quiet http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder.tgz -O - | tar -xz -C /dieharder_src/
}
cmd_24() { cd /dieharder_src/*
}
cmd_25() { cmd_24 && ./autogen.sh 
}
cmd_26() { cmd_24 && sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec
}
cmd_27() { cmd_24 && sed -i '129s/.*/# /' ./dieharder.spec
}
cmd_28() { cmd_24 && sed -i '16s/.*/chrpath gsl-dev/' ./dieharder.spec.in
}
cmd_29() { cmd_24 && sed -i '129s/.*/# /' ./dieharder.spec.in
}
cmd_30() { cmd_24 && sed -i '66i #define M_PI    3.14159265358979323846' ./include/dieharder/libdieharder.h
}
cmd_31() { cmd_24 && sed -i '262i typedef unsigned int uint;' ./include/dieharder/libdieharder.h
}
cmd_32() { cmd_24 && sed -i '263i \ ' ./include/dieharder/libdieharder.h
}
cmd_33() { echo "waiting..."
}
cmd_34() { cmd_24 && make install
}
cmd_len() { echo 34
}
