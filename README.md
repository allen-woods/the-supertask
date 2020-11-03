# The Supertask

Personal portfolio site and current passion project, tentatively planned for first production deployment by year's end, 2020.

## Mission Statement

> The ways we currently interact with information involve excess entropic disruption of daily life.
>
> Beyond this, the uncertain social fabric of the post-COVID near future will surely see an increasing demand for therapeutic social simulations to help mitigate the impacts of isolation.
>
> The future of interacting with data will involve integration with our surrounding environment that is seamless, sensory, intuitive, and behavioral, such that apps and trusted sites can evolve to become AR companions and personalized XR experiences.
>
> In short, the future of the web is in WebXR.
>
> This project humbly aims to offer a vision of what the experience- and memory-driven web of the near future may look like, given available technologies, in addition to serving as my portfolio toward pursuing programming professionally.

## Project Technologies

| Frontend                                                                                                                                                                                                                                                                                                                                                                                 | Backend                                                                                                                                                                                        |
| :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <image src="https://reactjs.org/favicon.ico" alt="ReactJS icon" style="width: 20px; height: 20px;" /> **[ReactJS](https://reactjs.org/)**                                                                                                                                                                                                                                                | <image src="https://caddyserver.com/resources/images/favicon.png" alt="Caddy icon" style="width: 20px; height: 20px;" /> **[Caddy Server](https://caddyserver.com/)** (TLS v1.3)               |
| <image src="https://www.babylonjs.com/favicon.ico" alt="BabylonJS icon" style="width: 20px; height: 20px;" /> **[BabylonJS](https://babylonjs.com/)** (<image src="https://raw.githubusercontent.com/immersive-web/webxr/master/images/spec-logo.png" alt="WebXR icon" style="width: 20px; height: 20px;" /> [WebXR](https://developer.mozilla.org/en-US/docs/Web/API/WebXR_Device_API)) | <image src="https://gqlgen.com/favicon.ico" alt="Gqlgen icon" style="width: 20px; height: 20px;" /> **[GraphQL](https://gqlgen.com/)**                                                         |
| <image src="https://www.blender.org/favicon.ico" alt="Blender icon" style="width: 20px; height: 20px;" /> **[Blender](https://www.blender.org/)** (assets)                                                                                                                                                                                                                               | <image src="https://grpc.io/favicon.ico" alt="gRPC icon" style="width: 20px; height: 20px;" /> **[gRPC](https://godoc.org/google.golang.org/grpc)**                                            |
| <image src="https://webassembly.org/favicon.ico" alt="WebAssembly icon" style="width: 20px; height: 20px;" /> **[WebAssembly](https://github.com/golang/go/wiki/WebAssembly)** _(stretch goal)_                                                                                                                                                                                          | <image src="https://redislabs.com/favicon.ico" alt="Redis icon" style="width: 20px; height: 20px;" /> **[Redis](https://godoc.org/github.com/go-redis/redis)**                                 |
|                                                                                                                                                                                                                                                                                                                                                                                          | :globe_with_meridians: **[UUID](https://godoc.org/github.com/satori/go.uuid)** (V4)                                                                                                            |
|                                                                                                                                                                                                                                                                                                                                                                                          | :gorilla: **[SecureCookie](https://godoc.org/github.com/gorilla/securecookie)**                                                                                                                |
|                                                                                                                                                                                                                                                                                                                                                                                          | :monocle_face: **Bespoke Hash/Block and Valid Cookie(s) Rotation**                                                                                                                             |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://www.mongodb.com/favicon.ico" alt="MongoDB icon" style="width: 20px; height: 20px;" />**[MongoDB](https://godoc.org/go.mongodb.org/mongo-driver)**                          |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://www.datocms-assets.com/2885/1597163356-vault-favicon.png?h=32&w=32" alt="Vault icon" style="width: 20px; height: 20px;" /> **[HashiCorp Vault](https://vaultproject.io/)** |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://gnupg.org/favicon.ico" alt="GnuPG icon" style="width: 20px; height: 20px;" /> **[GnuPG](https://gnupg.org/)** / **[OpenPGP Standard](https://www.openpgp.org/)**           |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://www.openssl.org/favicon.ico" alt="OpenSSL icon" style="width: 20px; height: 20px;" /> **[OpenSSL](https://www.openssl.org/)**                                              |
|                                                                                                                                                                                                                                                                                                                                                                                          | :no_entry: **[Argon2](https://github.com/P-H-C/phc-winner-argon2)** (Argon2id)                                                                                                                 |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://www.docker.com/favicon.ico" alt="Docker icon" style="width: 20px; height: 20px;" /> **[Docker Machine](https://docs.docker.com/machine/)**                                 |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://circleci.com/favicon.ico" alt="CircleCI icon" style="width: 20px; height: 20px;" /> **[CircleCI](https://circleci.com/)** _(stretch goal)_                                 |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://ubuntu.com/favicon.ico" alt="Ubuntu icon" style="width: 20px; height: 20px;" /> **[Ubuntu Server](https://ubuntu.com/)**                                                   |
|                                                                                                                                                                                                                                                                                                                                                                                          | <image src="https://pkgs.alpinelinux.org/assets/favicon.ico" alt="Alpine icon" style="width: 20px; height: 20px;" /> **[Alpine Linux](https://alpinelinux.org/)**                              |
|                                                                                                                                                                                                                                                                                                                                                                                          | :gear: **[POSIX Conformant Shell Scripts](https://www.grymoire.com/Unix/Sh.html)**                                                                                                             |

### TODO:

- **Clean up this messy README** (in progress)
- Dockerize local environment (ongoing)
- Begin building API
  - Design toward implementation of `Apollo Server` and `Apollo Client`. (on track)
  - **Provide single source of truth for models.**
    - _Codebase of Gqlgen and gRPC could potentially deviate, investigate any options that might prevent this._
  - **Create initialization for unique email fields requirement.**
    - gRPC "user" microservice will manage this.
  - Successfully create and persist the following accounts:
    - Global super user to replace "root" in MongoDB.
    - Database owners, each dedicated to a given microservice.
  - Included HashiCorp Vault image from Docker hub.
    - `root` of Vault will generate MongoDB superuser.
    - `superuser` of MongoDB will create database owner per gRPC service.
    - `dbOwner` secrets will be generated by and stored in Vault.
      - **Important: root token is created during init.**
      - Service tokens are heavyweight to create, but suffices for this build.
    - Vault secrets will be rotated to prevent brute force attacks.
    - Transit secrets will be used for data that does not need persistence.
    - Stretch goal: full end-to-end TLS encryption.

### DONE:

- Create draft of architecture
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
  - Added Argon2 for hardening KBKDF instead of PBKDF2 flag in OpenSSL.
