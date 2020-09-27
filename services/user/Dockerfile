FROM go:alpine

# Many thanks and much credit goes to Nico Vergauwen for this repo:
# - https://github.com/kyriediculous/go-grpc-mongodb
#
# This would have taken a lot longer without that to learn from.

# Set working directory to /code.
WORKDIR /code

# Copy over all contents of this service.
COPY --chown=root:root . .

# Copy over the service agnostic MongoDB authentication script.
COPY --chown=root:root ../sh ./.env/

# Copy over the MongoDB env vars.
COPY --chown=root:root ../../mongo/.env ./.env/

# Source all env vars used to connect to MongoDB from gRPC.
RUN ["/bin/sh", "source", "./.env/user-service-secrets.sh"]

# Run the gRPC server by default.
CMD ["/bin/sh", "go", "run", "./server/main.go"]