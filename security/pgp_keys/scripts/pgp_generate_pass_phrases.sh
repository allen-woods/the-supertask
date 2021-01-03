#!/bin/sh

# Utility function for generating random passphrases.
# Usage:
# generatePassPhrases [phrase_count] [regex_pattern]
function generatePassPhrases {
  local arg1=$(abs ${1:-4})
  local arg2=${2:-[[:alnum:]][[:punct:]]}
  local n=0
  local PHRASE=

  while [ $n -lt $arg1 ]
  do
    if [ -z PHRASE ]
    then
      PHRASE="$(randomString $arg2)"
    else
      PHRASE="$PHRASE $(randomString $arg2)"
    fi
    n=$(($n + 1))
  done
  echo -n $PHRASE
}