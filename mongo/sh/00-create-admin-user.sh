#!/bin/bash

# This file is being replaced by better shell scripting. (WIP)

INIT_JS_0="\\
db.createUser({ \\
  user: \"${MONGO_ADMIN_USER}\", \\
  pwd: \"${MONGO_ADMIN_PASS}\", \\
  roles: [ \\
    { \\
      role: \"userAdminAnyDatabase\", \\
      db: \"admin\" \\
    }, \"readWriteAnyDatabase\" \\
  ] \\
})"

init_00() {
  # Run the javascript inside of Mongo shell.
  gosu mongodb mongo admin \
  --host localhost \
  --port "27017" \
  --eval "${INIT_JS_0}"
}