#!/bin/sh

mkdir -pm 0755 /etc/ssl/certs /etc/ssl/private
cd /etc/ssl

echo 01 > serial
touch index.txt

# To avoid confusion, do these steps first.

# Patch line 46 to point `dir` to <where everything is kept>
# Patch line 78 to point `default_md` to sha512
# Patch line 109 to point `default_bits` to 4096
# Patch line 132 to point `countryName_default` to US
# Patch line 137 to point `stateOrProvinceName_default` to Washington
# Patch line 146 to point `0.organizationalName_default` to TheSupertask

# Now do these steps second.

# Insert new line 13 to add RANDFILE entry.
# Insert new line 111 to add `default_md = sha512` entry.
# Insert new line 142 to add `localityName_default = SEATTLE` entry.
# Insert new line 263 to add `[ v3_intermediate_ca ]` section tag.
# Insert new line 264 to add `subjectKeyIdentifier = hash` attribute.
# Insert new line 265 to add `authorityKeyIdentifier = keyid:always,issuer` attribute.
# Insert new line 266 to add `basicConstraints = critical, CA:true, pathlen:0` attribute.
# Insert new line 267 to add `keyUsage = critical, digitalSignature, cRLSign, keyCertSign` attribute.

# sed -i '13i RANDFILE                = \$ENV::HOME\/.rnd' ./openssl.cnf


mkdir -p /usr/local/share/ca-certificates


# Generate private key and self-signed certificate.
openssl req \
-x509 \
-nodes \
-new \
-sha512 \
-days 365 \
-newkey rsa:4096 \
-keyout ca.key \
-out ca.pem \
-subj "/C=US/CN=THE-SUPERTASK"

# Generate certificate file (CRT).
openssl x509 \
-outform PEM \
-in ca.pem \
-out ca.crt

# Generate x509 v3 extension file.
echo '
authorityKeyIdentifier = keyid, issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
# Local hosts
DNS.1 = localhost
DNS.2 = 127.0.0.1
DNS.3 = ::1
# List domains here
DNS.4 = www.thesupertask.com
DNS.5 = thesupertask.com
' >> v3.ext

# Generate private key and certificate sign request (CSR).
openssl req \
-new \
-nodes \
-newkey rsa:4096 \
-keyout localhost.key \
-out localhost.csr \
-subj "/C=US/ST=Washington/L=Seattle/O=The-Supertask/CN=www.thesupertask.com"

# Generate self-signed certificate (CRT).
openssl x509 \
-req \
-sha512 \
-days 365 \
-extfile v3.ext \
-CA ca.crt \
-CAkey ca.key \
-CAcreateserial \
-in localhost.csr \
-out localhost.crt