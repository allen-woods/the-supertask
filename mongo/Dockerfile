FROM mongo:bionic

# Set the working directory to the root of the container.
WORKDIR /

# Copy the env vars and superuser script.
COPY --chown=mongodb:mongodb ./mongo/.sh ./run/env-vars

RUN ["/bin/bash", "-c", ". /run/env-vars/00-export-env-vars.sh"]
RUN ["/bin/bash", "-c", "mongod --bind_ip $MONGO_IP --port $MONGO_PORT --fork --logpath /var/log/mongodb/mongod"]
RUN ["/bin/bash", "-c", "mongo --eval $MDB_JS"]
# RUN ["/bin/bash", "-c", "kill -HUP 1"]