#!/bin/bash

# Insert something into the new database to trigger persistence.
mongo --authenticationDatabase "$MONGO_API_DB"\
      -u "$MONGO_API_USER"\
      -p "$MONGO_API_PASS"\
      --eval "db.init.insert({ databaseExists: true });"
      /data/db