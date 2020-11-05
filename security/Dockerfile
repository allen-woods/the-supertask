FROM vault:1.5.4

WORKDIR /

# Copy over all config files to initialize Vault.
COPY --chown=root:root ./init/config /vault/config/

# Update the repository so it can see `sshpass` package.
RUN ["/bin/ash", "-c", "exec su root -c 'apk update'"]

# Install the `openssl` package at version "1.1.1g-r0" for Alpine 3.10.5.
RUN ["/bin/ash", "-c", "exec su root -c 'apk add \"openssl=1.1.1g-r0\"'"]

# Install the `argon2` package at version "20171227-r2" for Alpine 3.10.5.
# Resources: https://github.com/P-H-C/phc-winner-argon2
RUN ["/bin/ash", "-c", "exec su root -c 'apk add \"argon2=20171227-r2\"'"]

# The following adds the `sshpass` CLI utility to fully
# automate SSH secrets engine and OTP.

# Install the `sshpass` package at version "1.06-r0" for Alpine 3.10.5.
RUN ["/bin/ash", "-c", "exec su root -c 'apk add \"sshpass=1.06-r0\"'"]

# Install the `curl` package at version "7.66.0-r1" for Alpine 3.10.5.
RUN ["/bin/ash", "-c", "exec su root -c 'apk add \"curl=7.66.0-r1\"'"]

# Now we can safely upgrade all packages, if necessary.
RUN ["/bin/ash", "-c", "exec su root -c 'apk upgrade'"]

# Run in server mode.
CMD ["server"]
