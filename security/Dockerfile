# Name: supervault (TBD)
# Desc: This container provides a PGP-hardened instance of HashiCorp Vault
#       initialized to use TLS 1.3 certificates.
#
# Note: All private data that are mangaed and persisted outside of Vault in
#       compliance with best practice documentation are encrypted using the
#       id-aes256-wrap-pad algorithm.

FROM vault:latest AS builder

# Run the OpenSSL installation.
WORKDIR /
COPY --chown=root:root ["./vault/config",                                 "/vault/config/"]
COPY --chown=root:root ["./aes_wrap_enabled_openssl/install_openssl.sh",  "/etc/profile.d/"]
COPY --chown=root:root ["./run_install.sh",                               "/etc/profile.d/"]
RUN /bin/sh -c . /etc/profile/ && \
  install_openssl && \
  install_pgp && \
  install_tls && \
  initialize_vault

FROM vault:latest AS supervault

WORKDIR /
COPY --chown=root:root ./vault/config /vault/config/
CMD ["server"]