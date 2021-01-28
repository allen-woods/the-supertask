# 1 - Compile entropy tests.
FROM alpine:3.10.5 AS entropy_tests

WORKDIR /

COPY --chown=root:root ["./entropy_tests/scripts/install_lib.sh",   "/etc/profile.d/"]
COPY --chown=root:root ["./shared/scripts/run_install.sh",          "/etc/profile.d/"]

RUN ["/bin/sh", "-c", ". /etc/profile && run_install --verbose"]

# 2 - Generate certificates.
FROM alpine:3.10.5 AS cert_authority

WORKDIR /

COPY --chown=root:root ["./cert_authority/secret/.admin",           "/root/"]
COPY --chown=root:root ["./cert_authority/scripts/install_lib.sh",  "/etc/profile.d/"]
COPY --chown=root:root ["./shared/scripts/abs.sh",                  "/etc/profile.d/"]
COPY --chown=root:root ["./shared/scripts/escape_string.sh",        "/etc/profile.d/"]
COPY --chown=root:root ["./shared/scripts/pipe_crud.sh",            "/etc/profile.d/"]
COPY --chown=root:root ["./shared/scripts/random_string.sh",        "/etc/profile.d/"]
COPY --chown=root:root ["./shared/scripts/run_install.sh",          "/etc/profile.d/"]


RUN ["/bin/sh", "-c", ". /etc/profile && run_install --verbose"]

# # 3 - Generate PGP keys.
# FROM alpine:3.10.5 AS pgp_keys

# WORKDIR /

# PGP initialization.
# COPY --chown=root:root ["./pgp_keys/scripts/install_lib.sh",                "/etc/profile.d/"]
# COPY --chown=root:root ["./shared/scripts/run_install.sh",                  "/etc/profile.d/"]
# Utility functions.
# COPY --chown=root:root ["./shared/scripts/abs.sh",                          "/etc/profile.d/"]
# COPY --chown=root:root ["./shared/scripts/escape_string.sh",                "/etc/profile.d/"]
# COPY --chown=root:root ["./shared/scripts/pipe_crud.sh",                    "/etc/profile.d/"]
# COPY --chown=root:root ["./shared/scripts/random_string.sh",                "/etc/profile.d/"]
# # PGP data generation.
# # COPY --chown=root:root ["./pgp_keys/scripts/pgp_encrypt_pass_phrases.sh",   "/etc/profile.d/"]
# # COPY --chown=root:root ["./pgp_keys/scripts/pgp_export_keys.sh",            "/etc/profile.d/"]
# # COPY --chown=root:root ["./pgp_keys/scripts/pgp_generate_and_run_batch.sh", "/etc/profile.d/"]
# # COPY --chown=root:root ["./pgp_keys/scripts/pgp_generate_pass_phrases.sh",  "/etc/profile.d/"]
# # COPY --chown=root:root ["./pgp_keys/scripts/pgp_init_vault.sh",             "/etc/profile.d/"]
# # COPY --chown=root:root ["./pgp_keys/scripts/pgp_pass_keys_into_vault.sh",   "/etc/profile.d/"]

# RUN ["/bin/sh", "-c", ". /etc/profile && run_install --verbose"]

# # RUN ["/bin/sh", "-c", ". /etc/profile && addPGPPackages && generatePGPData"]
# # COPY --chown=root:root ./scripts/pipeWrite.sh /etc/profile.d/
# # COPY --chown=root:root ./scripts/pipeRead.sh /etc/profile.d/

# 4 - Copy DieHarder, Certificate, PGP data into Vault.
FROM vault:1.5.6 AS supervault

WORKDIR /

#COPY --from=entropy_tests /usr/bin/dieharder/ /usr/bin/dieharder/
#COPY --from=pgp_keys /pgp/ /pgp/
COPY --chown=root:root ./config /vault/config/
# COPY --chown=root:root ["./pgp_keys/scripts/pgp_init_vault.sh",           "/etc/profile.d/"]
# COPY --chown=root:root ["./pgp_keys/scripts/pgp_pass_keys_into_vault.sh", "/etc/profile.d/"]

# RUN ["/bin/sh", "-c", ". /etc/profile && pgp_init_vault"]
CMD ["server"]