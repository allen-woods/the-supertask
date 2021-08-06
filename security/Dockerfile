# Name: supervault (TBD)
# Desc: This container provides a PGP-hardened instance of HashiCorp Vault
#       initialized to use TLS 1.3 certificates.
#
# Note: All private data that are managed and persisted outside of Vault in
#       compliance with best practice documentation are encrypted using the
#       id-aes256-wrap-pad algorithm as implemented by a patched compile of
#       OpenSSL.

# Proposed Steps:
#   X DieHarder Test Suite.
#   X Compile OpenSSL.
#   X PGP data.
#   X Unseal Vault.
#   Configure Vault.
#   TLS data.
FROM alpine:3.12.7 AS test-suite
WORKDIR /
COPY --chown=root:root  [ \
  "./sh/pretty.sh", \
  "./sh/run_install.sh", \
  "./sh/install_dieharder.sh", \
  "/etc/profile.d/" \
  ]
RUN [ "/bin/sh", "-c", ". /etc/profile && run_install --verbose /etc/profile.d/install_dieharder.sh" ]

FROM alpine:3.13.5 AS aes-wrap
WORKDIR /
COPY --chown=root:root  [ \
  "./sh/pretty.sh", \
  "./sh/run_install.sh", \
  "./sh/install_openssl.sh", \
  "/etc/profile.d/" \
  ]
RUN [ "/bin/sh", "-c", ". /etc/profile && run_install --verbose /etc/profile.d/install_openssl.sh" ]

FROM vault:1.7.1 AS vault-init
WORKDIR /

# DieHarder Test Suite.
COPY --chown=root:root --from=test-suite  [ \
  "/usr/bin/dieharder", \
  "/usr/bin/" \
  ]

COPY --chown=root:root --from=test-suite  [ \
  "/usr/lib/libdieharder.so.3", \
  "/usr/lib/libgsl.so.25", \
  "/usr/lib/libgslcblas.so.0", \
  "/usr/lib/" \
  ]

# AES-Wrap (OpenSSL).
COPY --chown=root:root --from=aes-wrap    [ \
  "/root/local/bin/openssl", \
  "/root/local/bin/openssl.sh", \
  "/root/local/bin/" \
  ]

COPY --chown=root:root --from=aes-wrap    [ \
  "/usr/bin/aes-wrap", \
  "/usr/bin/" \
  ]

COPY --chown=root:root --from=aes-wrap    [ \
  "/lib/ld-musl-aarch64.so.1", \
  "/lib/libc.musl-aarch64.so.1", \
  "/lib/libcrypto.so.1.1", \
  "/lib/libssl.so.1.1", \
  "/lib/" \
  ]

COPY --chown=root:root --from=aes-wrap    [ \
  "/root/local/lib", \
  "/root/local/lib/" \
  ]

COPY --chown=root:root  [ \
  "./sh/hilbert.sh", \
  "./sh/get_earthcam_entropy_image.sh", \
  "./sh/pretty.sh", \
  "./sh/run_install.sh", \
  "./sh/utf8_char.sh", \
  "./sh/utf8_char_file.sh", \
  "./sh/utf8_passphrase.sh", \
  "./sh/install_pgp.sh", \
  "/etc/profile.d/" \
  ]

# #  /etc/profile.d/install_tls.sh
COPY --chown=root:root  [ "./vault/config",            "/vault/config/" ]
#COPY --chown=root:root  [ "./tls/.admin",              "/root/" ]
COPY --chown=root:root  [ "./static/char_file.utf8",   "/root/.aes_rsa_utf8_support/character_set/" ] 
COPY --chown=root:root  [ "./credentials/credentials", "/var/tmp/" ]

RUN [ "/bin/sh", "-c", ". /etc/profile && run_install --verbose /etc/profile.d/install_pgp.sh" ]

# FROM vault:1.7.1 AS supervault
# WORKDIR /

# COPY --chown=root:root --from=vault-init [ "./vault/config", "/vault/config/" ]
# CMD [ "server" ]
#RUN [ "/bin/sh", "-c", "vault server -config /vault/config/" ]