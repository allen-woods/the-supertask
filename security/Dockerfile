FROM alpine:3.10.5 AS pgp_keys

WORKDIR /

COPY --chown=root:root ["./scripts/addPGPPackages.sh",          "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/abs.sh",                     "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/echoHorizontalRule.sh",      "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/encryptPassPhrases.sh",      "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/escapeString.sh",            "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/exportPGPKeys.sh",           "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/generateAndRunPGPBatch.sh",  "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/generatePassPhrases.sh",     "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/generatePGPData.sh",         "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/initVaultWithPGP.sh",        "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/passPGPKeysIntoVault.sh",    "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/randomString.sh",            "/etc/profile.d/"]
RUN ["/bin/sh", "-c", ". /etc/profile && addPGPPackages && generatePGPData"]
# COPY --chown=root:root ./scripts/pipeWrite.sh /etc/profile.d/
# COPY --chown=root:root ./scripts/pipeRead.sh /etc/profile.d/

# FROM alpine:3.10.5 AS ca_files

# WORKDIR /
# # We need to copy scripts related to certificates
# COPY --chown=root:root ./scripts/ca_files /etc/profile.d/
# RUN ["/bin/sh", "-c", ". /etc/profile && \
#   generate_trust_chain"]

# FROM alpine:3.10.5 AS entropy_tools

# WORKDIR /
# # We need to copy scripts related to entropy tools
# COPY --chown=root:root ./scripts/entropy_tools /etc/profile.d/
# RUN ["/bin/sh", "-c", ". /etc/profile && \
#   entropy_func_name"]

FROM vault:1.5.6 AS supervault

WORKDIR /

COPY --from=pgp_keys /pgp/ /pgp/
COPY --chown=root:root ./config /vault/config/
COPY --chown=root:root ["./scripts/echoHorizontalRule.sh",    "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/initVaultWithPGP.sh",      "/etc/profile.d/"]
COPY --chown=root:root ["./scripts/passPGPKeysIntoVault.sh",  "/etc/profile.d/"]

RUN ["/bin/sh", "-c", ". /etc/profile && initVaultWithPGP"]
CMD ["server"]