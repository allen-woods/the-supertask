FROM alpine:3.10.5 AS enc-builder

WORKDIR /
COPY --chown=root:root ["./install_openssl.sh", "/etc/profile.d/"]
RUN ["/bin/sh", "-c", ". /etc/profile && \
  run_install --verbose \
  /etc/profile.d/install_openssl.sh"]