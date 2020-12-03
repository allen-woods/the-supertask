FROM vault:1.5.4
WORKDIR /
COPY --chown=root:root ./config /vault/config/
COPY --chown=root:root ./scripts /etc/profile.d/
RUN ["/bin/ash", "-c", "exec su root -c 'apk update && apk add \
  \"gnupg=2.2.19-r0\" \
  \"openssl=1.1.1g-r0\" \
  \"outils-jot=0.8-r1\" && apk upgrade'"]
CMD ["server"]