#!/bin/sh

# Utility function for generating random passphrases.
# Usage:
# pgp_generate_pass_phrases [phrase_count] [regex_pattern]
function pgp_generate_pass_phrases {
  local arg1=$(abs ${1:-4})
  local arg2=${2:-[[:alnum:]][[:punct:]]}
  local n=0
  local PHRASE=

  while [ $n -lt $arg1 ]
  do
    if [ -z PHRASE ]
    then
      PHRASE="$(random_string $arg2)"
    else
      PHRASE="$PHRASE $(random_string $arg2)"
    fi
    n=$(($n + 1))
  done
  echo -n $PHRASE
}