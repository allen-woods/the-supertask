FROM vault:1.5.4

WORKDIR /

# Copy over all config files to initialize Vault.
COPY --chown=root:root ./init/config /vault/config/
COPY --chown=root:root ./init /usr/local/init/

# Update the repository so it can see `sshpass` package.
# RUN ["/bin/ash", "-c", "exec su root -c 'apk update'"]

# Update the apk repository.
# Install the following packages for Alpine 3.10.5:
#
# - argon2    \"argon2=20171227-r2\"
# - curl      \"curl=7.66.0-r1\"
# - gnupg     \"gnupg=2.2.19-r0\"
# - jot       \"outils-jot=0.8-r1\"
# - jq        \"jq=1.6-r0\"
# - openssl   \"openssl=1.1.1g-r0\"
# - sshpass   \"sshpass=1.06-r0\"
#
# Upgrade apps in the apk repository, where possible.
RUN ["/bin/ash", "-c", "exec su root -c 'apk update && apk add \
  \"argon2=20171227-r2\" \
  \"curl=7.66.0-r1\" \
  \"gnupg=2.2.19-r0\" \
  \"outils-jot=0.8-r1\" \
  \"jq=1.6-r0\" \
  \"openssl=1.1.1g-r0\" \
  \"sshpass=1.06-r0\" && apk upgrade'"]

# Run in server mode.
CMD ["server"]
