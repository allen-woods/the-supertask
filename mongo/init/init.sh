#!/bin/bash

# Bring in our environment variables.
source /usr/local/etc/custom-init/export-env-vars.sh

echo "$MDB_JS" | xargs

# Create a mongod instance for us to run our initialization against.
mongod --bind_ip_all \
--port $MONGO_PORT \
--fork \
--logpath /var/log/mongodb/mongod

# Create a mongo client that injects MDB_JS and initializes our superuser.
mongo $MONGO_INITDB_DATABASE \
--host $MONGO_IP \
--port $MONGO_PORT \
--eval $MDB_JS \
--quiet