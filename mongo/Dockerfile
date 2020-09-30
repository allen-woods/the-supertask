FROM mongo:bionic

# Set the working directory to the root of the container.
WORKDIR /

# Copy the env vars and superuser script.
COPY --chown=mongodb:mongodb ./mongo/.env/mongo-secrets.sh ./usr/local/bin/