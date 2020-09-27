# /bin/bash

# This file is being replaced by better shell scripting. (WIP)

INIT_JS_1="\\
db.createUser({ \\
  user: \"${MONGO_API_USER}\", \\
  pwd: \"${MONGO_API_PASS}\", \\
  roles: [ \\
    { \\
      role: \"readWrite\", \\
      db: \"${MONGO_API_DB}\" \\
    }, \"readWrite\" \\
  ] \\
})"

init_01(){
  # Run the javascript inside of Mongo shell.
  gosu mongodb mongo admin \
  --host localhost \
  --port "27017" \
  --eval "${INIT_JS_1}" \
  -u "${MONGO_ADMIN_USER}" \
  -p "${MONGO_ADMIN_PASS}" \
  --authenticationDatabase "admin"
}