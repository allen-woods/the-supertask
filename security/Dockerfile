FROM vault:1.5.4

WORKDIR /
COPY --chown=root:root ./config /vault/config/
COPY --chown=root:root ./scripts /etc/profile.d/

# Chain commands in RUN to reduce number of intermediate containers.
RUN ["/bin/sh", "-c", ". /etc/profile && \
  alpine_to_stable && add_packages"]
# && entropy_tests"]
CMD ["server"]