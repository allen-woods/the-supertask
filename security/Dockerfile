FROM alpine:3.10.5 AS pgp_keys

WORKDIR /
# We need to copy scripts related to pgp keys.

FROM alpine:3.10.5 AS ca_files

WORKDIR /
# We need to copy scripts related to certificates

FROM alpine:3.10.5 AS entropy_tools

WORKDIR /
# We need to copy scripts related to entropy tools

FROM vault:1.5.4

WORKDIR /
# We need to copy files from previous builds, etc.

COPY --chown=root:root ./config /vault/config/
COPY --chown=root:root ./scripts /etc/profile.d/

# Chain commands in RUN to reduce number of intermediate containers.
RUN ["/bin/sh", "-c", ". /etc/profile && \
  alpine_to_stable && add_packages"]
# && entropy_tests"]
CMD ["server"]