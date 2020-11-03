#!/bin/sh

# Generate a Base64 string from the plain text argument $1.
# Store the result in a file named `cert-phrase` in the current directory.
echo $(echo -n "${$1}" | \
openssl dgst -sha256 -binary | \
openssl base64) > "$(pwd)"/cert-phrase

# Encrypt the contents of `cert-phrase` into a new file `cert-phrase.enc`.
openssl enc \
-aes-128-gcm -pbkdf2 \
-in "$(pwd)"/cert-phrase \
-out "$(pwd)"/cert-phrase.enc \
-pass pass:somethinghere \
-salt