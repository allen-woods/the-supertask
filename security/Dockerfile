# Name: supervault (TBD)
# Desc: This container provides a PGP-hardened instance of HashiCorp Vault
#       initialized to use TLS 1.3 certificates.
#
# Note: All private data that are managed and persisted outside of Vault in
#       compliance with best practice documentation are encrypted using the
#       id-aes256-wrap-pad algorithm as implemented by a patched compile of
#       OpenSSL.

FROM vault:latest AS builder

# Run the OpenSSL installation.
WORKDIR /
COPY --chown=root:root \
  ./vault/config, /vault/config/, \
  ./run_install.sh, /etc/profile.d/, \
  ./aes_wrap_enabled_openssl/install_openssl.sh, /etc/profile.d/, \
  ./pgp/install_pgp.sh, /etc/profile.d/, \
  ./tls/install_tls.sh, /etc/profile.d/
RUN /bin/sh -c . /etc/profile/ && \
  run_install \
  /etc/profile.d/install_openssl.sh \
  /etc/profile.d/install_pgp.sh \
  /etc/profile.d/install_tls.sh

FROM vault:latest AS supervault

WORKDIR /
COPY --chown=root:root ./vault/config /vault/config/
CMD ["server"]