FROM vault:1.5.4

WORKDIR /

# Copy over all config files to initialize Vault.
COPY --chown=root:root ./init/config /vault/config/

# Add the `sshpass` CLI utility to fully automate SSH secrets engine and OTP.
RUN "apk update && apk upgrade && apk add sshpass"

# Run in server mode.
CMD ["server"]
