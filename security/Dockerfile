# Name: supervault (TBD)
# Desc: This container provides a PGP-hardened instance of HashiCorp Vault
#       initialized to use TLS 1.3 certificates.
#
# Note: All private data that are managed and persisted outside of Vault in
#       compliance with best practice documentation are encrypted using the
#       id-aes256-wrap-pad algorithm as implemented by a patched compile of
#       OpenSSL.

FROM vault:1.7.1 AS init-src

WORKDIR /
COPY --chown=root:root [ "./vault/config",          "/vault/config/" ]
COPY --chown=root:root [ "./tls/.admin",            "/root/"]
COPY --chown=root:root [ "./sh/apk_loader.sh",      "/etc/profile.d/" ]
COPY --chown=root:root [ "./sh/pretty.sh",          "/etc/profile.d/" ]
COPY --chown=root:root [ "./sh/run_install.sh",     "/etc/profile.d/" ]
COPY --chown=root:root [ "./sh/install_openssl.sh", "/etc/profile.d/" ]
COPY --chown=root:root [ "./sh/install_pgp.sh",     "/etc/profile.d/" ]
COPY --chown=root:root [ "./sh/install_tls.sh",     "/etc/profile.d/" ]
RUN [ "/bin/sh", "-c", ". /etc/profile && \
  run_install --verbose \
  /etc/profile.d/install_openssl.sh \
  /etc/profile.d/install_pgp.sh \
  /etc/profile.d/install_tls.sh" ]

FROM vault:1.7.1 AS supervault
# Clean install that copies in things from the other images

WORKDIR /
COPY --chown=root:root --from=init-src [ "./vault/config", "/vault/config/" ]
CMD ["server"]