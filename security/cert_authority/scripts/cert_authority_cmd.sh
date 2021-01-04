#!/bin/sh

cmd_01() { apk.static add openssl
}
cmd_02() { apk.static add outils-jot
}
cmd_03() { openssl req -x509 -nodes -new -sha512 -days 365 -newkey rsa:4096 -keyout ca.key -out ca.pem -subj "/C=US/CN=THE-SUPERTASK"
}
cmd_len() {
  echo 03
}