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

| Frontend                                                                                                                                                                                                                                                                                                                                                     | Backend                                                                                                                                                                          |
| :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://reactjs.org/favicon.ico" alt="ReactJS icon" width="20" height="20" /> **[ReactJS](https://reactjs.org/)**                                                                                                                                                                                                                                  | <img src="https://caddyserver.com/resources/images/favicon.png" alt="Caddy icon" width="20" height="20" /> **[Caddy Server](https://caddyserver.com/)** _(TLS v1.3)_             |
| <img src="https://www.apollographql.com/favicon.ico" alt="Apollo icon" width="20" height="20" /> **[Apollo Client](https://www.apollographql.com/)**                                                                                                                                                                                                         | <img src="https://gqlgen.com/favicon.ico" alt="Gqlgen icon" width="20" height="20" /> **[GraphQL](https://gqlgen.com/)**                                                         |
| <img src="https://www.babylonjs.com/favicon.ico" alt="BabylonJS icon" width="20" height="20" /> **[BabylonJS](https://babylonjs.com/)** (<img src="https://raw.githubusercontent.com/immersive-web/webxr/master/images/spec-logo.png" alt="WebXR icon" width="20" height="20" /> [WebXR](https://developer.mozilla.org/en-US/docs/Web/API/WebXR_Device_API)) | <img src="https://grpc.io/favicon.ico" alt="gRPC icon" width="20" height="20" /> **[gRPC](https://godoc.org/google.golang.org/grpc)**                                            |
| <img src="https://www.blender.org/favicon.ico" alt="Blender icon" width="20" height="20" /> **[Blender](https://www.blender.org/)** _(assets)_                                                                                                                                                                                                               | <img src="https://redislabs.com/favicon.ico" alt="Redis icon" width="20" height="20" /> **[Redis](https://godoc.org/github.com/go-redis/redis)**                                 |
| <img src="https://webassembly.org/favicon.ico" alt="WebAssembly icon" width="20" height="20" /> **[WebAssembly](https://github.com/golang/go/wiki/WebAssembly)** _(stretch goal)_                                                                                                                                                                            | :globe_with_meridians: **[UUID](https://godoc.org/github.com/satori/go.uuid)** _(V4)_                                                                                            |
|                                                                                                                                                                                                                                                                                                                                                              | :gorilla: **[SecureCookie](https://godoc.org/github.com/gorilla/securecookie)**                                                                                                  |
|                                                                                                                                                                                                                                                                                                                                                              | :monocle_face: **Bespoke Cookie Rotation**                                                                                                                                       |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://www.mongodb.com/favicon.ico" alt="MongoDB icon" width="20" height="20" />**[MongoDB](https://godoc.org/go.mongodb.org/mongo-driver)**                          |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://www.datocms-assets.com/2885/1597163356-vault-favicon.png?h=32&w=32" alt="Vault icon" width="20" height="20" /> **[HashiCorp Vault](https://vaultproject.io/)** |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://gnupg.org/favicon.ico" alt="GnuPG icon" width="20" height="20" /> **[GnuPG](https://gnupg.org/)** / **[OpenPGP Standard](https://www.openpgp.org/)**           |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://www.openssl.org/favicon.ico" alt="OpenSSL icon" width="20" height="20" /> **[OpenSSL](https://www.openssl.org/)**                                              |
|                                                                                                                                                                                                                                                                                                                                                              | :no_entry: **[Argon2](https://github.com/P-H-C/phc-winner-argon2)** _(Argon2id)_                                                                                                 |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://www.docker.com/favicon.ico" alt="Docker icon" width="20" height="20" /> **[Docker Machine](https://docs.docker.com/machine/)**                                 |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://circleci.com/favicon.ico" alt="CircleCI icon" width="20" height="20" /> **[CircleCI](https://circleci.com/)** _(stretch goal)_                                 |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://ubuntu.com/favicon.ico" alt="Ubuntu icon" width="20" height="20" /> **[Ubuntu Server](https://ubuntu.com/)**                                                   |
|                                                                                                                                                                                                                                                                                                                                                              | <img src="https://pkgs.alpinelinux.org/assets/favicon.ico" alt="Alpine icon" width="20" height="20" /> **[Alpine Linux](https://alpinelinux.org/)**                              |
|                                                                                                                                                                                                                                                                                                                                                              | :gear: **[POSIX Conformant Shell Scripts](https://www.grymoire.com/Unix/Sh.html)**                                                                                               |

## TODO:

#### Site Plan (ERD)

- [ ] Finalize overview map of site resources.
- [ ] Finalize detail map of GraphQL models and resolvers.
- [ ] Finalize single responsibilities of gRPC microservices.
- [ ] Finalize detail map of MongoDB aggregation pipelines.
- [ ] Consolidate actions into clearly defined roles.

---

#### Docker Compose

- [ ] Configure appropriate `dev` and `prod` environment.
- [ ] Migrate to `docker-machine` when CI/CD pipeline is operational.

---

#### Vault

> **NOTE:**
> This is the meat of the backend configuration and is taking me the most time. The rest of the build needs this section of work completed in order to further development in all other areas.
>
> The guaranteed computational delay built into Argon2's KBKDF is vital to preventing ASIC / GPU brute force attacks.

- [ ] Complete `gen_trust_chain` POSIX shell utility. _(OpenSSL, Argon2id)_
- [ ] Copy `gen_trust_chain` script into Vault container.
- [ ] Generate `*.pem` files required by TLS.
- [ ] Reference `*.pem` files correctly in config where needed.
- [ ] Complete config in `/vault/config/local.json`.
- [ ] Create policies for roles determined in ERD.
- [ ] Run `gpg --gen-key` _offline_.
- [ ] **Store private key(s) in hardware, _NOT_ on a network**.
- [ ] Export public key(s) as standard **unarmored base64** or **binary**.
- [ ] Copy `<key_name>.asc` file(s) into Vault container.
- [ ] Run `vault operator init` with `-pgp-keys` flag to harden with PGP. ([Details](https://www.vaultproject.io/docs/concepts/pgp-gpg-keybase))
- [ ] Enable PKI secrets engine. ([Details](https://www.vaultproject.io/docs/secrets/pki))
- [ ] Enable the TLS Certificate authentication method. ([Details](https://www.vaultproject.io/docs/auth/cert))

---

#### CircleCI

> **NOTE:**
> While this is a "nice-to-have", this topic is ubiquitous and important to understand. _Prioritize gaining experience with this_.

- [ ] Read documentation thoroughly.
- [ ] Give extra attention to closures and orbs _("secrets" obfuscation)_.
- [ ] Build CI/CD pipeline. _(revisit and expand this entry based on steps needed)_
- [ ] Reach :skateboard: level MVP before implementing CI/CD.

---

#### GraphQL

- [ ] Modularize `schema.graphql` into model-specific files.
- [ ] Write schema IDL for remaining models.
- [ ] Declare values of type for remaining models as determined in ERD.
- [ ] Implement all resolvers for all models.

---

#### gRPC

- [ ] Create gRPC miscroservices that correspond to Vault roles.
- [ ] Implement full CRUD on all microservices where appropriate.
- [ ] Store documents by `mongo-driver/bson/primitive.ObjectID`, not `int`.
- [ ] Enforce unique email fields index on `users` microservice. _(MongoDB)_

---

#### MongoDB

- [ ] Configure `mongod` to use TLS.
- [ ] Serve daemon with `--directoryperdb` flag.
- [ ] Generate obfuscated `root` superuser.
- [ ] Allocate and persist databases that are needed.
- [ ] Create and persist `dbOwner` admin account for each `gRPC, role` pair.

---

## DONE:

- [x] First draft of architecture overview.
- [x] Pulled `docker/redis` container.
- [x] Pulled `docker/mongo` container.
- [x] Implemented MongoDB with obfuscated authentication.
- [x] Implemented POSIX conformant shell scripts for MongoDB.
- [x] Implemented Redis with disabled THP support.
- [x] Implemented data store persistence.
- [x] Wrote schema IDL for value of type `User`.
- [x] Generated model and resolvers for value of type `User`.
- [x] Populated resolvers with logic.
