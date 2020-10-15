FROM mongo:bionic 

WORKDIR /usr/local/etc
COPY --chown=root:root ./mongo/init/authorization /usr/local/etc/mongodb/
COPY --chown=root:root ./mongo/init/init.sh /usr/local/bin/

RUN ["/bin/bash", "-c", "exec gosu root apt-get update"]
RUN ["/bin/bash", "-c", "exec gosu root apt-get -y install curl"]
RUN /usr/local/bin/init.sh