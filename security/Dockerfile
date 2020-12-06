FROM vault:1.5.4

# \"gcc=8.3.0-r0\" \
# \"musl=1.1.22-r4\" \
# \"musl-dev=1.1.22-r4\" \

WORKDIR /
COPY --chown=root:root ./config /vault/config/
COPY --chown=root:root ./scripts /etc/profile.d/
# RUN ["/bin/ash", "-c", "exec su root -c 'apk add \
#   \"busybox-static=1.30.1-r4\" \
#   \"apk-tools-static=2.10.4-r2\" && \
#   sed -i -e 's/v3\.10/v3.12/g' /etc/apk/repositories && \
#   apk.static update && \
#   apk.static upgrade --no-self-upgrade --available'"]

# apk.static add \
# \"gawk=5.1.0-r0\" \
# \"g++=9.3.0-r2\" \
# \"gnupg=2.2.23-r0\" \
# \"gsl=2.6-r0\" \
# \"gsl-dev=2.6-r0\" \
# \"gsl-doc=2.6-r0\" \
# \"haveged=1.9.8-r1\" \
# \"libc-dev=0.7.2-r3\" \
# \"libtool=2.4.6-r7\" \
# \"make=4.3-r0\" \
# \"openssl=1.1.1g-r0\" \
# \"outils-jot=0.9-r0\" \
# \"rng-tools=6.10-r2\" \
# \"rpm=4.15.1-r2\" && \
# mkdir -m 0700 /etc/dieharder && \
# chown root:root /etc/dieharder && \
# wget -c http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder-3.31.1.tgz -O - | \
# tar -xz -C /etc/dieharder/ && \
# echo \"PATH=$PATH\" > ~/.shrc && \
# . ~/.shrc'"]

#  && \
# cd /etc/dieharder/* && \
# ./autogen.sh && \
# make install'"]
CMD ["server"]