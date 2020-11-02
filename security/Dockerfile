FROM vault:1.5.4

WORKDIR /

# Copy over all config files to initialize Vault.
COPY --chown=root:root ./init/config /vault/config/

# Add the `sshpass` CLI utility to fully automate SSH secrets engine and OTP.
RUN ["/bin/ash", "-c", "exec su root -c 'apk update'"]
RUN ["/bin/ash", "-c", "exec su root -c 'apk add \"sshpass=1.06-r0\"'"]
RUN ["/bin/ash", "-c", "exec su root -c 'apk upgrade'"]

# Run in server mode.
CMD ["server"]
