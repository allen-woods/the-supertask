FROM golang:alpine

# Many thanks and much credit goes to Nico Vergauwen for this repo:
# - https://github.com/kyriediculous/go-grpc-mongodb
#
# This would have taken a lot longer without that to learn from.

# Set working directory to /code.
WORKDIR /code

# Copy over all contents of this service.
COPY --chown=root:root ./services/user ./

# Copy over the service agnostic MongoDB authentication script.
COPY --chown=root:root ./services/sh ./.env/

# Copy over the MongoDB env vars.
COPY --chown=root:root ./mongo/.env ./.env/

# Add the curl package to Alpine.
RUN ["apk", "add", "curl"]

# Source all env vars used to connect to MongoDB from gRPC.
RUN ["/bin/sh", ".", "/code/.env/user-service-secrets.sh"]

# Run the gRPC server by default.
CMD ["go", "run", "/code/server/main.go"]