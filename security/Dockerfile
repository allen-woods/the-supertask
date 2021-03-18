# # 1 - Compile entropy tests.
# FROM alpine:3.10.5 AS builder

# WORKDIR /
# VOLUME [ "persist_vault_private_files:/persist" ]
# COPY --chown=root:root ["./pgp/install_pgp.sh",   "/etc/profile.d/"]
# COPY --chown=root:root ["./tls/install_tls.sh",   "/etc/profile.d/"]
# COPY --chown=root:root ["./tls/.admin",           "/root/"]
# COPY --chown=root:root ["./run_install.sh",       "/etc/profile.d/"]
# RUN ["/bin/sh", "-c", ". /etc/profile && \
#   run_install --verbose \
#   /etc/profile.d/install_pgp.sh \
#   /etc/profile.d/install_tls.sh"]

# FROM builder AS obfuscator

# WORKDIR /
# VOLUME [ "./manage_private_files:/to_host" ]
# COPY --chown=root:root ["./migrate_files.sh",     "/etc/profile.d/"]
# COPY --chown=root:root --from=builder /persist/ /persist/
# COPY --chown=root:root --from=builder /pgp/ /pgp/
# COPY --chown=root:root --from=builder /tls/ /tls/
# RUN ["/bin/sh", "-c", ". /etc/profile && migrate_files"]

FROM vault:1.5.6 AS supervault

WORKDIR /
COPY --chown=root:root ./vault/config /vault/config/
#COPY --chown=root:root --from=obfuscator /pgp/ /pgp/
#COPY --chown=root:root --from=obfuscator /tls/ /tls/
CMD ["server"]