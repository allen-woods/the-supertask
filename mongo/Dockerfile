FROM mongo:bionic

# Set the working directory to the root of the container.
WORKDIR /

# Copy the env vars and superuser script.
COPY --chown=mongodb:mongodb ./mongo/init ./usr/local/etc/custom-init/

RUN ["/bin/bash", "-c", "/usr/local/etc/custom-init/init.sh"]