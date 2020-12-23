#!/bin/sh

function init {
  local output=${output:-"Trust Chain Initialized!"}

  if [ ! -d "/tls" ]
  then
    generate_trust_chain
  else
    output="SKIPPING: trust chain already initialized."
  fi

  echo "$output"
}

function generate_trust_chain {
  create_trust_path root
  create_trust_path intermediate
  populate_trust_path root
  populate_trust_path intermediate
}

function create_trust_path {
  local output=${output:-"Trust Paths Created!"}

  if [ -d "/tls/${1}" ]
  then
    output="SKIPPING: directory /tls/${1} already created."
  else
    mkdir -pm ${2:-0755} /tls/$1/private
    mkdir -m ${2:-0755} /tls/$1/certs
  fi

  echo "${output}"
}

function populate_trust_path {
  [ ! -f "/tls/$1/serial" ]     && echo 01 >> /tls/$1/serial  || echo "SKIPPING: file /tls/$1/serial already exists."
  [ ! -f "/tls/$1/index.txt" ]  && touch /tls/$1/index.txt    || echo "SKIPPING: file /tls/$1/index.txt already exists."

  if [ -f "/tls/$1/serial" ] || [ -f "/tls/$1/index" ]
  then
    echo "SKIPPING: directory /tls/$1 already populated."
  else
    echo 01 >> /tls/$1/serial
    touch /tls/$1/index.txt
  fi
}

function pipe_w {
  local pipe=${1:-"test"}
  local data=${2:-"the quick brown fox jumps over the lazy dog"}
  local flag=${3:-"--overwrite"}
  local first_run=0
  local sync=

  if [ ! -p $pipe ]
  then
    # Create the pipe if it doesn't exist.
    mkfifo $pipe
    
    # Set `first_run` for proper data handling below.
    first_run=1
  fi

  if [ $first_run -eq 0 ] && [ "${flag}" == "--overwrite" ]
  then
    # Empty the pipe completely, and silently.
    ( ( echo ' ' >> $pipe & ) && echo "$(cat < ${pipe})" ) > /dev/null 2>&1
    
    # Set `first_run` for proper data handling below.
    first_run=1
  fi

  if [ $first_run -eq 0 ] && [[ -z $sync ]]
  then
    # If we are appending data, front-load contents of pipe.
    sync="$(cat < ${pipe})"
  fi

  for item in $data
  do
    if [ $first_run -eq 1 ]
    then
      # Pipe is empty, place first item into `sync`.
      sync="${item}"

      # Unset `first_run` to indicate start of data collection.
      first_run=0
    else
      # Data has collected at least one thing, append item to `sync`.
      sync="$(printf "%s\n" "${sync}" "${item}")"
    fi
  done

  # Silently place contents of `sync` into pipe. 
  ( echo "${sync}" > $pipe & )
}

function pipe_r {
  local pipe=${1:-"test"}
  local item=${2:-0}
  local flag=${3:-"--no-destroy"}
  local sync=
  local data=

  # Require the pipe to exist so we can read from it.
  if [ -p $pipe ] && [[ ! -z $pipe ]]
  then
    # Extract the contents of the pipe.
    sync="$(cat < ${pipe})"

    if [ $item -eq 0 ]
    then
      # Place all `sync` data into requested `data`.
      data="${sync}"

    elif [ $item -gt 0 ]
    then
      # Place requested item from `sync` into `data`.
      data="$(echo "${sync}" | sed "${item}q;d")"

    fi

    if [ "${flag}" == "--no-destroy" ]
    then
      # Pass all previous `sync` data back into pipe.
      ( echo "${sync}" > $pipe & ) > /dev/null 2>&1

    elif [ "${flag}" == "--keep-item-only" ] && [ $item -gt 0 ]
    then
      # Pass only requested `data` (item) back into pipe.
      ( echo "${data}" > $pipe & ) > /dev/null 2>&1

    elif [ "${flag}" == "--destroy-item" ] && [ $item -gt 0 ]
    then
      # Pass mutated data back into pipe with `item` removed.
      ( echo "$(echo "${sync}" | sed "${item}d")" > $pipe & ) > /dev/null 2>&1

    elif [ "${flag}" == "--destroy-all" ]
    then
      # Delete the pipe, silently.
      ( rm -f $pipe ) > /dev/null 2>&1

    fi

    # Send the requested `data` to stdout.
    echo "${data}"
  fi
}

# function create_certs {
#   mkdir -pm 0755 /etc/ssl/certs /etc/ssl/private
#   cd /etc/ssl

#   echo 01 > serial
#   touch index.txt

#   # To avoid confusion, patch lines first...

#     # Patch line 45 to point `dir` to <where everything is kept>
#     sed -i '45s/demoCA/thesupertask/' ./openssl.cnf

#     # Patch line 77 to point `default_md` to sha512
#     sed -i '77s/= default/= sha512' ./openssl.cnf

#     # Patch line 108 to point `default_bits` to 4096
#     sed -i '108s/2048/4096/' ./openssl.cnf

#     # Patch line 131 to point `countryName_default` to US
#     sed -i '131s/AU/US/' ./openssl.cnf

#     # Patch line 136 to point `stateOrProvinceName_default` to Washington
#     sed -i '136s/Some-State/Washington' ./openssl.cnf

#     # Patch line 141 to point `0.organizationalName_default` to TheSupertask
#     sed -i '141s/Internet\ Widgits\ Pty\ Ltd/The\ Supertask/' ./openssl.cnf

#   # ... Add lines second.

#     # Insert new line 13 to add RANDFILE entry.
#     sed -i '13i RANDFILE = \$ ENV::HOME\/.rnd' ./openssl.cnf

#     # Insert new line 111 to add `default_md = sha512` entry.
#     sed -i '111i default_md = sha512' ./openssl.cnf

#     # Insert new line 142 to add `localityName_default = SEATTLE` entry.
#     sed -i '142i localityName_default = SEATTLE' ./openssl.cnf

#     # Insert new line 263 to add `[ v3_intermediate_ca ]` section tag.
#     sed -i '263i [ v3_intermediate_ca ]' ./openssl.cnf

#     # Insert new line 264 to add `subjectKeyIdentifier = hash` attribute.
#     sed -i '264i subjectKeyIdentifier = hash' ./openssl.cnf

#     # Insert new line 265 to add `authorityKeyIdentifier = keyid:always,issuer` attribute.
#     sed -i '265i authorityKeyIdentifier = keyid:always,issuer' ./openssl.cnf

#     # Insert new line 266 to add `basicConstraints = critical, CA:true, pathlen:0` attribute.
#     sed -i '266i basicConstraints = critical, CA:true, pathlen:0' ./openssl.cnf

#     # Insert new line 267 to add `keyUsage = critical, digitalSignature, cRLSign, keyCertSign` attribute.
#     sed -i '267i keyUsage = critical, digitalSignature, cRLSign, keyCertSign' ./openssl.cnf

#   # End patch/add lines.

#   # Generate private key and self-signed certificate.
#   openssl req \
#   -x509 \
#   -nodes \
#   -new \
#   -sha512 \
#   -days 365 \
#   -newkey rsa:4096 \
#   -keyout ca.key \
#   -out ca.pem \
#   -subj "/C=US/CN=THE-SUPERTASK"

#   # Generate certificate file (CRT).
#   openssl x509 \
#   -outform PEM \
#   -in ca.pem \
#   -out ca.crt

#   # Generate x509 v3 extension file.
#   echo '
#   authorityKeyIdentifier = keyid, issuer
#   basicConstraints = CA:FALSE
#   keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
#   subjectAltName = @alt_names
#   [alt_names]
#   # Local hosts
#   DNS.1 = localhost
#   DNS.2 = 127.0.0.1
#   DNS.3 = ::1
#   # List domains here
#   DNS.4 = www.thesupertask.com
#   DNS.5 = thesupertask.com
#   ' >> v3.ext

#   # Generate private key and certificate sign request (CSR).
#   openssl req \
#   -new \
#   -nodes \
#   -newkey rsa:4096 \
#   -keyout localhost.key \
#   -out localhost.csr \
#   -subj "/C=US/ST=Washington/L=Seattle/O=The-Supertask/CN=www.thesupertask.com"

#   # Generate self-signed certificate (CRT).
#   openssl x509 \
#   -req \
#   -sha512 \
#   -days 365 \
#   -extfile v3.ext \
#   -CA ca.crt \
#   -CAkey ca.key \
#   -CAcreateserial \
#   -in localhost.csr \
#   -out localhost.crt

#   # This is how the GoLinuxCloud tutorial said to generate and sign intermediate certificate.
#   openssl ca \
#   -config openssl.cnf \
#   -extensions v3_intermediate_ca \
#   -days 2650 \
#   -notext \
#   -batch \
#   -passin file:mypass.enc \
#   -in intermediate/csr/intermediate.csr.pem \
#   -out intermediate/certs/intermediate.cacert.pem
# }