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

- Dockerize local environment (ongoing)
- Implement `docker/mongo` and `docker/redis`
  - Implement MongoDB with Authentication
    - Wrote custom shell scripts for initializing database.
    - Implemented string interpolation of environment variables to keep secrets secure.
    - Researched and feasibility tested `heredoc` and escaped line break options for more readable JavaScript (all failed).
  - Implement Redis securely (done)
    - Fixed broken config support in `docker-compose` using `chown` and the `redis` user inside the image.
    - Disable THP support inside the container.
    - Removed unnecessary volume "persist_redis_backups" (should be /data).
  - Make sure both data stores are persisted (done)
- Begin building API
  - Added placeholder types in schema file.
  - Authentication
    - Create User type, model, and resolvers.
