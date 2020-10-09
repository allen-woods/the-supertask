FROM mongo:bionic

# Set the working directory to the location of docker-entrypoint.sh.
# We do this to copy to multiple locations.
WORKDIR /usr/local/bin

# Place our monkey patcher into the container.
COPY --chown=root:root ./mongo/init/docker-entrypoint.sh ./