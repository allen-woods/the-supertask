#!/bin/bash

# Bring in our environment variables.
source /usr/local/etc/custom-mongo-init/includes/mongo-init-env-vars.sh

# echo $(echo -n "${MDB_JS//[[:space:]]/}")

# Create a mongod instance for us to run our initialization against.
mongod --bind_ip_all \
--port $MONGO_PORT \
--fork \
--logpath=/var/log/mongodb/mongod \
--directoryperdb \
--eval $MDB_JS

# Create a mongo client that injects MDB_JS and initializes our superuser.
mongo $MONGO_INITDB_DATABASE \
--host $MONGO_IP \
--port $MONGO_PORT \
--eval $(echo -n "${MDB_JS//[[:space:]]/}") \
--quiet