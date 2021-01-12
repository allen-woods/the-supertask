#!/bin/sh

cert_authority_patch_intermediate_cnf() {
  sed -i '46s/=\ \/tls\/root/=\ \/tls\/intermediate/' /tls/intermediate/openssl.cnf.intermediate
  sed -i '54s/=\ \$dir\/certs\/cacert.pem/=\ \$dir\/certs/intermediate.cacert.pem/' /tls/intermediate/openssl.cnf.intermediate
  sed -i '59s/=\ \$dir\/private\/cakey.pem/=\ \$dir\/private\/intermediate.cakey.pem/' /tls/intermediate/openssl.cnf.intermediate
  sed -i '84s/=\ policy_match/=\ policy_anything/' /tls/intermediate/openssl.cnf.intermediate
}