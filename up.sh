#!/bin/sh

project_up() {
  local ENC_UTIL_IMAGE_NAME=the-supertask_wrapper
  
  echo "$(tput lines) $(tput cols)" > ./security/misc/pseudo_tty

  cd ./security 
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 1\033[0m" && return 1

  # Only Build AES Wrap-Enabled OpenSSL if necessary.
  if [ -z "$(docker images | grep -o ${ENC_UTIL_IMAGE_NAME})" ]; then
    pretty "Image \"${ENC_UTIL_IMAGE_NAME}\" Needs to be Built :("
    
    # Build OpenSSL image.
    docker build --no-cache \
    --tag the-supertask_wrapper:latest \
    --target wrap-enabled \
    --rm --compress \
    --file ./aes_wrap_enabled_openssl/Dockerfile \
    .
    [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 2\033[0m" && return 1
  else
    pretty "Image \"${ENC_UTIL_IMAGE_NAME}\" Ready to Go! :)"
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
  docker cp $(pwd)/pretty.sh enc_util:/etc/profile.d/
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

  # # Copy gnupg data into Vault container.
  docker cp enc_util:/root/.gnupg/ $(pwd)/private_files/.gnupg/
  docker cp $(pwd)/private_files/.gnupg/ truth_src:/root/.gnupg/

  # Copy the pretty utility function into Vault's container.
  docker cp $(pwd)/pretty.sh truth_src:/etc/profile.d/

  # Copy the PGP key migration script into Vault's container.
  docker cp $(pwd)/pgp/vault_operator_init_pgp_key_shares.sh truth_src:/etc/profile.d/
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 8\033[0m" && return 1

  # Run the script to initialize Vault with PGP hardening.
  docker exec -it \
  truth_src \
  /bin/sh -c '. /etc/profile && \
  vault_operator_init_pgp_key_shares'
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 9\033[0m" && return 1

  docker cp truth_src:/to_host/vault $(pwd)/private_files/vault
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 10\033[0m" && return 1

  # Copy the TLS parsing script into Vault's container.
  docker cp $(pwd)/tls/vault_v1_pki_config_ca_submit_ca_information.sh truth_src:/etc/profile.d/
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 11\033[0m" && return 1

  # Run the script to configure the PKI Secrets Engine to use TLS.
  docker exec -it \
  truth_src \
  /bin/sh -c '. /etc/profile && \
  vault_v1_pki_config_ca_submit_ca_information'
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 12\033[0m" && return 1

  cd "${OLDPWD}"
  [ ! $? -eq 0 ] && echo -e "\033[7;31mThere Was a Problem with Command 13\033[0m" && return 1

  pretty "Entering OpenSSL Container \"enc_util\"."
  docker exec -it enc_util /bin/sh
}

project_up