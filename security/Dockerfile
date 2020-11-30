FROM vault:1.5.4

WORKDIR /

# Copy over all config files to initialize Vault.
COPY --chown=root:root ./config /vault/config/
COPY --chown=root:root ./scripts /etc/profile.d/

# Update the repository so it can see `sshpass` package.
# RUN ["/bin/ash", "-c", "exec su root -c 'apk update'"]

# Update the apk repository.
# Install the following packages for Alpine 3.10.5:
#
# - gnupg     \"gnupg=2.2.19-r0\"
# - jot       \"outils-jot=0.8-r1\"
# - openssl   \"openssl=1.1.1g-r0\"
#
# Upgrade apps in the apk repository, where possible.
RUN ["/bin/ash", "-c", "exec su root -c 'apk update && apk add \
  \"gnupg=2.2.19-r0\" \
  \"openssl=1.1.1g-r0\" \
  \"outils-jot=0.8-r1\" && apk upgrade'"]

# Run in server mode.
CMD ["server"]

# Execute custom initialization
RUN ["/bin/sh", "-c", "exec su root -c '. /etc/profile && init_vault_with_pgp'"]
