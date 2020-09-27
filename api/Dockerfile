FROM go:alpine

# Set the working directory to where the code is copied.
WORKDIR /code

# Copy local code over to the image.
COPY --chown=root:root . .
COPY --chown=root:root ../redis/.env/redis-secrets.sh ./.env/redis-secrets.sh

# Source the script used to populate env variables.
RUN /bin/sh source ./.env/api-secrets.sh

# Start the server by default.
CMD go run /code/server.go