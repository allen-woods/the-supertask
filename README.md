# The Supertask

Personal portfolio site for the second half of 2020.

Technologies planned for project:

- Caddy Server
- CircleCI
- Custom Authentication
- Docker Machine
- Golang
- GraphQL
- MongoDB
- ReactJS
- Redis
- WebAssembly

### TODO:

- Dockerize local environment
- Implement `docker/mongo` and `docker/redis`
  - Implement MongoDB with Authentication
  - Implement Redis securely (done)
    - Fixed broken config support in `docker-compose` using `chown` and the `redis` user inside the image.
    - Disable THP support inside the container.
    - Removed unnecessary volume "persist_redis_backups" (should be /data).
  - Make sure both data stores are persisted (done)
- Begin building API
