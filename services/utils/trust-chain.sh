#!/bin/sh

# Work in progress!

# Currently following:
# https://www.alexedwards.net/blog/how-to-hash-and-verify-passwords-with-argon2-in-go

argon_pass = "$(gen random string here)"
argon_salt = "$(gen random string here)"
argon_hash = "$(echo -n $argon_pass | argon2 $argon_salt -id -t 12 -m 16 -p 1 -l 32 -r -v 13)"
argon_encd = "$(echo -n $argon_pass | argon2 $argon_salt -id -t 12 -m 16 -p 1 -l 32 -e -v 13)"

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