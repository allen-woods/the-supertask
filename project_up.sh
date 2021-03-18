#!/bin/sh

project_up() {
  cd ./security
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 1\033[0m" && return 1

  # Build OpenSSL image.
  docker build --no-cache \
  --target wrap-enabled \
  --rm --compress \
  --file ./aes_wrap_enabled_openssl/Dockerfile \
  .
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 2\033[0m" && return 1

  # Run instance of image.
  docker run -d --entrypoint "/bin/sh" -it --name enc_util \
  --user root:root \
  --mount type=bind,src=$(pwd)/private_files,dst=/to_host/ \
  --mount type=volume,src=persist_v111_build,dst=/root/ \
  --mount type=volume,src=persist_pgp,dst=/pgp/ \
  --mount type=volume,src=persist_tls,dst=/tls/ \
  --rm=false \
  the-supertask_wrapper
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 3\033[0m" && return 1

  # Copy files into  container.
  docker cp $(pwd)/pgp/install_pgp.sh enc_util:/etc/profile.d/
  docker cp $(pwd)/tls/install_tls.sh enc_util:/etc/profile.d/
  docker cp $(pwd)/tls/.admin enc_util:/root/
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 4\033[0m" && return 1

  # Execute commands inside container.
  docker exec -it enc_util \
  /bin/sh -c '. /etc/profile && \
  run_install --verbose /etc/profile.d/install_pgp.sh'
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 5\033[0m" && return 1

  docker exec -it enc_util \
  /bin/sh -c '. /etc/profile && \
  run_install --verbose /etc/profile.d/install_tls.sh'
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 6\033[0m" && return 1

  # Spin up compose project.
  docker-compose build --force-rm --no-cache
  docker-compose up -d
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 7\033[0m" && return 1

  cd "${OLDPWD}"
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 8\033[0m" && return 1
}

project_up