# /bin/bash

INIT_JS_1="\
// Switch to database theSupertask.
use $MONGO_API_DB;\
\
// Create the user authorized to access the API.
db.createUser(\
  {\
    user: \"$MONGO_API_USER\",\
    pwd: \"$MONGO_API_PASS\",\
    roles: [\"readWrite\"]\
  }\
);"

# Restart the mongod process under the mongodb user in the image.
gosu mongodb mongod --auth --bind_ip_all

# Run the javascript inside of Mongo shell.
mongo --authenticationDatabase "admin"\
      -u "$MONGO_ADMIN_USER"\
      -p "$MONGO_ADMIN_PASS"\
      --eval "$INIT_JS_1"\
      /data/db