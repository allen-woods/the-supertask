FROM mongo:bionic

# Set the working directory to the root of the container.
WORKDIR /

# Copy in all contents of the '/mongo' directory.
COPY --chown=root:root ./mongo ./

# Source the script used to populate env variables and functions.
RUN ["/bin/sh", ".", "/.env/mongo-secrets.sh"]

# Generate the superuser for MongoDB by default.
CMD ["/bin/sh", "mongo_create_super_user_account"]