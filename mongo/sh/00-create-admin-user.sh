#!/bin/bash

INIT_JS_0="\
// Switch to the admin database.\
use admin;\
\
// Create the superuser acount dbAdmin.\
db.createUser(\
  {\
    user: \"$MONGO_ADMIN_USER\",\
    pwd: \"$MONGO_ADMIN_PASS\",\
    roles: [\
      {\
        role: \"userAdminAnyDatabase\", db: \"admin\"\
      }, \"readWriteAnyDatabase\"\
    ]\
  }\
);\
\
// Shut down mongod.\
db.adminCommand(\
  {\
    shutdown: 1\
  }\
);"

# Run the javascript inside of Mongo shell.
mongo --eval "$INIT_JS_0" /data/db 