# The Supertask

Personal portfolio site for the second half of 2020.

Technologies planned for project:

- Caddy Server
- CircleCI
- Custom Authentication
- Docker Machine
- Golang
- GraphQL (gqlgen)
- MongoDB
- ReactJS
- Redis
- <em>WebAssembly (?)</em>

### TODO:

- Dockerize local environment (ongoing)
- Create draft of architecture (done)
- Begin building API
  - Design toward implementation of `Apollo Server` and `Apollo Client`. (on track)
  - **Provide single source of truth for models.**
    - Included HashiCorp Vault image from Docker hub.
    - Undecided: transit secrets / read write secrets.
  - **Define Redis and MongoDB secrets as environment variables.**
    - These will be managed by Vault, see above.
  - **Create initialization for unique email fields requirement.**
    - gRPC "user" microservice will manage this.
  - Successfully create and persist the following accounts:
    - Global super user to replace "root" in MongoDB.
    - Database owners, each dedicated to a given microservice.

### DONE:

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
- API
  - Define User schema. (done)
  - Generate User model and resolvers. (done)
  - Populate resolvers with logic. (in progress)
