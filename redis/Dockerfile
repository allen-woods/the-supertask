FROM redis:alpine

# Set working directory to the root of the shared path for Redis defaults.
WORKDIR /usr/local

# Copy over the config.
COPY --chown=redis:redis ./config ./etc/redis/

# Copy over the env vars.
COPY --chown=root:root ./.env ./bin/

# Copy over the custom script(s).
COPY --chown=root:root ./sh ./bin/

# Disable THP using custom script.
RUN ["/bin/sh", "./bin/disable-thp-support.sh"]

# Source the env vars used to auth Redis.
RUN ["/bin/sh", "source", "./bin/redis-secrets.sh"]

# Start the server with our custom config by default.
CMD ["/bin/sh", "redis-server", "./etc/redis/redis.conf"]