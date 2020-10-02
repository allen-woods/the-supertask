#!/bin/bash

# The IP, Container, and Port of this MongoDB server.
export MONGO_IP="127.0.0.1"
export MONGO_CONTAINER=mongo
export MONGO_PORT=27017

# Built-in superuser.
export MONGO_INITDB_ROOT_USERNAME=root
export MONGO_INITDB_ROOT_PASSWORD=root
export MONGO_INITDB_DATABASE=admin

# This is a replacement of the default "root" user.
export MONGO_GLOBAL_SUPER_USERNAME=flynn
export MONGO_GLOBAL_SUPER_PASSWORD=H4e9aYpFBt4tSuZNfsjS2f2wvp6/0HweVD/AL1nyr9OMwzZFPUCBB4QiAEo0x7g21bhSX4riDKdiv/1n

read -r -d '' MDB_JS <<< "
if (db.system
      .users
      .find({
        \"user\": \"$MONGO_GLOBAL_SUPER_USERNAME\"
      }).count() < 1) {
  db.createUser({
    \"user\": {
      \"user\": \"$MONGO_GLOBAL_SUPER_USERNAME\",
      \"pwd\": \"$MONGO_GLOBAL_SUPER_PASSWORD\",
      \"customData\": {
        \"description:\" \"A global administration account for all databases within this MongoDB server.\"
      },
      \"roles\":[
        {
          \"role\": \"root\",
          \"db\": \"admin\"
        }
      ]
    }
  });
  db.removeUser(\"root\")};
  quit();
"

export MDB_JS