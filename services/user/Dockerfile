FROM golang:alpine

# Many thanks and much credit goes to Nico Vergauwen for this repo:
# - https://github.com/kyriediculous/go-grpc-mongodb
#
# This would have taken a lot longer without that to learn from.

# Set working directory to root of the container.
WORKDIR /

# Copy over all contents of the config for this service.
COPY --chown=root:root ./services/user/init ./usr/local/etc/custom-user-service-init/

# Copy over the service agnostic MongoDB authentication script.
COPY --chown=root:root ./services/utils/service-mongo-script.sh ./usr/local/etc/custom-user-service-init/includes/

# Copy over the Golang and Proto3 of this service.
COPY --chown=root:root ./services/user/app ./app/

# Add the curl package to Alpine.
RUN ["apk", "add", "curl"]

# Source all env vars used to connect to MongoDB from gRPC.
RUN ["/bin/sh", "-c", "/usr/local/etc/custom-user-service-init/init.sh"]

# Run the gRPC server by default.
CMD ["go", "run", "/app/server/main.go"]