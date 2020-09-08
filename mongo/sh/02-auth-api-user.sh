#!/bin/bash

init_02(){
  # Insert something into the new database to trigger persistence.
  gosu mongodb mongo ${MONGO_API_DB} \
  --host localhost \
  --port "27017" \
  --eval "db.init.insert({ databaseExists: true });" \
  -u "${MONGO_API_USER}" \
  -p "${MONGO_API_PASS}" \
  --authenticationDatabase "admin"
}