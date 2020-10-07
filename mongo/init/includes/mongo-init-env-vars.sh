#!/bin/bash

# The IP, Container, and Port of this MongoDB server.
export MONGO_IP="127.0.0.1"
export MONGO_CONTAINER=mongo
export MONGO_PORT=27017

# Built-in superuser.
export MONGO_INITDB_ROOT_USERNAME=root
export MONGO_INITDB_ROOT_PASSWORD=root
export MONGO_INITDB_DATABASE=admin

source /usr/local/etc/custom-mongo-init/mongo-credentials.sh

read -r -d '' MDB_JS <<< "
if (db.system
      .users
      .find({
        \"user\": \"$MONGO_GLOBAL_SUPER_USERNAME\"
      }).count() < 1) {
  db.adminCommand({
    dropUser: \"root\"
  });
  db.adminCommand({
    \"createUser\": \"$MONGO_GLOBAL_SUPER_USERNAME\",
    \"pwd\": \"$MONGO_GLOBAL_SUPER_PASSWORD\",
    \"roles\":[
      { \"role\": \"root\", \"db\": \"admin\" }
    ]
  })
};
quit();
"

export MDB_JS