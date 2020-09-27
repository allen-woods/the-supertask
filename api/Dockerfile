FROM golang:alpine

# Set the working directory to where the code is copied.
WORKDIR /code

# Copy local code over to the image.
COPY --chown=root:root ./api ./
COPY --chown=root:root ./redis/.env ./.env/

# Source the script used to populate env variables.
RUN ["/bin/sh", "/code/.env/api-secrets.sh"]

# Start the server by default.
CMD ["/bin/sh", "go", "run", "/code/server.go"]
EXPOSE 9000