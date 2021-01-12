#!/bin/sh

cert_authority_patch_root_cnf() {
  # Patches first.
  sed -i '45s/.\/demoCA/\/tls\/root/' /tls/root/openssl.cnf.root
  sed -i '51s/=\ \$dir\/newcerts/=\ \$dir\/certs' /tls/root/openssl.cnf.root
  sed -i '53s/=\ \$dir\/cacert.pem/=\ \$dir\/certs/cacert.pem/' /tls.root/openssl.cnf.root
  sed -i '77s/=\ default/=\ sha512' /tls/root/openssl.cnf.root
  sed -i '108s/=\ 2048/=\ 4096/' /tls/root/openssl.cnf.root
  sed -i '131s/=\ AU/=\ US/' /tls/root/openssl.cnf.root
  sed -i '136s/=\ Some-State/=\ Washington' /tls/root/openssl.cnf.root
  sed -i '141s/=\ Internet\ Widgits\ Pty\ Ltd/=\ The\ Supertask/' /tls/root/openssl.cnf.root
  sed -i '160s/=\ 4/=\ 20/' /tls/root/openssl.cnf.root # 128 bit, [[:alnum:]][[:punct:]]
  sed -i '161s/=\ 20/=\ 39/' /tls/root/openssl.cnf.root # 256 bit, [[:alnum:]][[:punct:]]

  # Inserts second.
  sed -i '12a RANDFILE = \$ENV::HOME\/.rnd' /tls/root/openssl.cnf.root
  sed -i '110a default_md = sha512' /tls/root/openssl.cnf.root # Breaking?
  sed -i '140a localityName_default = SEATTLE' /tls/root/openssl.cnf.root
  sed -i '261a [ v3_intermediate_ca ]' /tls/root/openssl.cnf.root
  sed -i '262a subjectKeyIdentifier = hash' /tls/root/openssl.cnf.root
  sed -i '263a authorityKeyIdentifier = keyid:always,issuer' /tls/root/openssl.cnf.root
  sed -i '264a basicConstraints = critical, CA:true, pathlen:0' /tls/root/openssl.cnf.root
  sed -i '265a keyUsage = critical, digitalSignature, cRLSign, keyCertSign' /tls/root/openssl.cnf.root
}