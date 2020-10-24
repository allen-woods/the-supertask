#!/bin/sh

# NOTE:
# This script will ignore seed files after first run.
#
# During subsequent runs of the container image, it
# will be the responsibility of `truth_src` to rotate
# MongoDB credentials.

# Declare vars.
first_user=0
first_pass=0
seed="/usr/local/etc/mongodb/mongo-seed"

# Read from the username seed file.
while IFS= read -r user
do
  case "$user" in
  # Username initialization data was found.
  *temp*) first_user=1 ;;
  esac
done < "${seed}-username"

# Read from the password seed file.
while IFS= read -r pass
do
  case "$pass" in
    # Password initialization data was found.
  *temp*) first_pass=1 ;;
  esac
done < "${seed}-password"

# Only if all initialization data is present...
if [ $first_user -eq 1 ] && [ $first_pass -eq 1 ]; then

  ####################################
  # This is first run of the script. #
  ####################################

  # ...Update the root username to a random 32
  # character string.
  echo "$(< /dev/urandom tr -dc A-Za-z0-9 | head -c32)\n" > "${seed}-username"
  
fi

