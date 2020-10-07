FROM redis:alpine

# Set working directory to the root of the container.
WORKDIR /

# Copy the system settings needed to disable THP.
COPY --chown=redis:redis ./redis/init/config/defrag ./sys/kernel/mm/transparent_hugepage/
COPY --chown=redis:redis ./redis/init/config/enabled ./sys/kernel/mm/transparent_hugepage/

# Copy the custom initialization files.
COPY --chown=redis:redis ./redis/init ./usr/local/etc/custom-redis-init/

# Remove the THP setting duplicates.
RUN rm /usr/local/etc/custom-redis-init/config/defrag
RUN rm /usr/local/etc/custom-redis-init/config/enabled

# Populate the env vars using the initialization script.
RUN ["/bin/sh", "-c", "/usr/local/etc/custom-redis-init/init.sh"]

# Start the server with our custom config by default.
CMD ["/bin/sh", "-c", "redis-server /usr/local/etc/custom-redis-init/config/redis.conf"]