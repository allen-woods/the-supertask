#!/bin/sh

: "\\
Pull in environment variables and data needed to connect to MongoDB
on the Docker network."
. /code/.env/mongo-secrets.sh

: "\\
Creating superUser account with global permissions is the responsibility
of the 'mongo_svc' container, defined in '/mongo'.

Any service only needs to use the credentials of superUser to create
resources (admin, database)."
create_service_mongo_admin_and_db() {
  svcName=$1
  adminPass=$2
  dbName=$3

  curl -u $MONGO_SUPER_USERNAME:$MONGO_SUPER_PASSWORD \
  -i -X POST -H 'Content-Type: application/json' -d "\\
  if (db.getMongo().getDBNames().indexOf(\"${dbName}\") < 0) { \\
    use ${dbName}; \\
    db.resources.insert({ allocated: true }); \\
  } \\
  /* Switch to the admin database */ \\
  use admin; \\
  if (db.system.users.find({ \\
    user: \"${svcName}ServiceAdmin\" \\
  }).count() !== 1) { \\
    /* We need to create the admin account for this service. */ \\
    db.CreateUser({ \\
      user: { \\
        user: \"${svcName}ServiceAdmin\", \\
        pwd: \"${adminPass}\", \\
        customData: { \\
          description: \"An administration account for the '${svcName}' service, restricted to the '${dbName}' database.\"
        }, \\
        roles: [ \\
          { \\
            role: \"userAdmin\", \\
            db: \"${dbName}\"
          }, \"readWrite\" \\
        ] \\
      } \\
    }); \\
  }" http://$MONGO_CONTAINER:$MONGO_PORT

  : "\\
  For security, unset the environment variables related to superUser,
  with respect to this container.
  We won't be needing these past this point."
  unset MONGO_SUPER_USERNAME
  unset MONGO_SUPER_PASSWORD
}

# Export the function so we can call it from the terminal.
export create_service_mongo_admin_and_db