#!/bin/sh

# Utility function for parsing end exporting generated keys.
# Usage:
# pgp_export_keys [revoc_path] [export_path] [prefix_string]
function pgp_export_keys {
  local arg1=${1:-${HOME}/.gnupg/openpgp-revocs.d/*}
  local arg2=${2:-/pgp/keys}
  local arg3=${3:-'key'}
  local n=1

  cd $arg2
  
  for file in $arg1
  do
    gpg2 \
    --export \
    "$(basename "$file" | cut -f 1 -d '.')" | \
    base64 > "$arg2/$arg3$n.asc"

    n=$(($n + 1))
  done
}