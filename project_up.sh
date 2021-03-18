#!/bin/sh

project_up() {
  local ENC_UTIL_IMAGE_NAME=the-supertask_wrapper

  cd ./security 
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 1\033[0m" && return 1

  # Only Build AES Wrap-Enabled OpenSSL if necessary.
  if [ -z "$(docker images | grep -o ${ENC_UTIL_IMAGE_NAME})" ]; then
    echo -e "\033[7;31m\n                                                  \nImage ${ENC_UTIL_IMAGE_NAME} Needs to be Built :( \n                                                  \033[0m"
    # Build OpenSSL image.
    docker build --no-cache \
    --tag the-supertask_wrapper:latest \
    --target wrap-enabled \
    --rm --compress \
    --file ./aes_wrap_enabled_openssl/Dockerfile \
    .
    [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 2\033[0m" && return 1
  else
    echo -e "\033[7;32m\n                                              \n Image ${ENC_UTIL_IMAGE_NAME} Already Built :) \n                                              \033[0m"
  fi

  # Run instance of image.
  docker run -d --entrypoint "/bin/sh" -it --name enc_util \
  --user root:root \
  --mount type=bind,src=$(pwd)/private_files,dst=/to_host/ \
  --mount type=volume,src=persist_v111_build,dst=/root/ \
  --mount type=volume,src=persist_pgp,dst=/pgp/ \
  --mount type=volume,src=persist_tls,dst=/tls/ \
  --rm=false \
  ${ENC_UTIL_IMAGE_NAME}
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 3\033[0m" && return 1

  # Copy files into  container.
  docker cp $(pwd)/pgp/install_pgp.sh enc_util:/etc/profile.d/
  docker cp $(pwd)/tls/install_tls.sh enc_util:/etc/profile.d/
  docker cp $(pwd)/tls/.admin enc_util:/root/
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 4\033[0m" && return 1

  # Execute commands inside container.
  docker exec -it \
  -e OPENSSL_V111=/root/local/bin/openssl.sh \
  enc_util \
  /bin/sh -c '. /etc/profile && \
  run_install --verbose /etc/profile.d/install_pgp.sh'
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 5\033[0m" && return 1

  docker exec -it \
  -e OPENSSL_V111=/root/local/bin/openssl.sh \
  enc_util \
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