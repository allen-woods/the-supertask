FROM redis:alpine

# Set working directory to the root of the container.
WORKDIR /

# Copy the system settings needed to disable THP.
COPY --chown=root:root ./redis/system/defrag ./sys/kernel/mm/transparent_hugepage/defrag
COPY --chown=root:root ./redis/system/enabled ./sys/kernel/mm/transparent_hugepage/enabled

# Copy over the config.
COPY --chown=redis:redis ./redis/config ./usr/local/etc/redis/

# Copy over the env vars.
COPY --chown=root:root ./redis/.env ./usr/local/bin/

# NOTE:
# The below won't work, not sure why.
# Needs Alpine equivalent of 'export -f'.

# Copy over the custom script(s).
# COPY --chown=root:root ./redis/sh ./bin/

# Disable THP using custom script.
# RUN ["/bin/sh", "/usr/local/bin/disable-thp-support.sh"]

# Source the env vars used to auth Redis.
RUN ["/bin/sh", ".", "/usr/local/bin/redis-secrets.sh"]

# Start the server with our custom config by default.
CMD ["/bin/sh", "./redis-server", "/usr/local/etc/redis/redis.conf"]