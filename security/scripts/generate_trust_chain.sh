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

  if [ -d "/tls/$1" ]
  then
    output="SKIPPING: directory /tls/$1 already created."
  else
    mkdir -pm ${2:-0755} /tls/$1/private
    mkdir -m ${2:-0755} /tls/$1/certs
  fi

  echo "$output"
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

function write_pipe_test {
  # When n = 0, overwrite line 1        (the)
  # When n = 1, insert new line after 1 (quick)
  # when n = 2, insert new line after 2 (brown)
  # when n = 3, insert new line after 3 (fox)
  # when n = 4, insert new line after 4 (jumps)
  # when n = 5, insert new line after 5 (over)
  # when n = 6, insert new line after 6 (the)
  # when n = 7, insert new line after 7 (lazy)
  # ... uh oh, "dog." is missing!

  # Remember, in bourne shell, if anything fails, it all fails.

  local data=${1:-"the quick brown fox jumps over the lazy dog"}
  local pipe=${2:-pp}
  local n=1
  if [ ! -p $pipe ]
  then
    mkfifo $pipe
  fi

  # Initialize the pipe with empty data.
  echo ' ' > $pipe &
  # Overwrite the

  for item in $data
  do
    if [[ $n -eq 1 ]]
    then
      # First item overwrites empty data prior to line inserts.
      sed -i "${n}s/.*/${item}/" $pipe &
    fi
    # All items insert after the nth line.
    sed -i "${n}a ${item}" $pipe &
    
    echo "n is ${n}, item is ${item}..."

    n=$(($n + 1))
  done
}

function read_pipe_test {
  local pipe=${1:-pp}
  echo $(cat < $pipe)
  # rm $pipe # Remove pipe?
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