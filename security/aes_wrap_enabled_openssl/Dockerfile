FROM alpine:3.10.5 AS builder

WORKDIR /
COPY --chown=root:root ["./aes_wrap_enabled_openssl/install_openssl.sh",  "/etc/profile.d/"]
COPY --chown=root:root ["./run_install.sh",                               "/etc/profile.d/"]
RUN ["/bin/sh", "-c", ". /etc/profile && openssl_apk_add_packages"]
RUN ["dumb-init", "/bin/sh", "-c", ". /etc/profile && run_install --verbose /etc/profile.d/install_openssl.sh"]

FROM builder AS wrap-enabled

WORKDIR /
COPY --chown=root:root --from=builder ["/root/", "/root/"]
COPY --chown=root:root ["./aes_wrap_enabled_openssl/docker-entrypoint.sh",  "/usr/local/bin"]
ENV OPENSSL_V111=/root/local/bin/openssl.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/docker-entrypoint.sh"]