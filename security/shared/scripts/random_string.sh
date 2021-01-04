#!/bin/sh

# Utility function for generating random strings.
# Usage:
# random_string [regex_pattern] [min_length] [max_length]
random_string() {
  local arg1=${1:-a-f0-9}
  local arg2=
  local arg3=

  if [ ! -z $2 ] && [ ! -z $3 ]
  then
    if [ $(abs $3) -lt $(abs $2) ]
    then
      arg2=$(abs ${3:-40})
      arg3=$(abs ${2:-99})
    else
      arg2=$(abs ${2:-40})
      arg3=$(abs ${3:-99})
    fi
  fi

  if [ -z $arg2 ] || [ -z $arg3 ]
  then
    arg2=40
    arg3=99
  fi

  local output=

  if [[ $arg2 -eq $arg3 ]]
  then
    output=$( \
      echo -n $( \
      tr -cd $arg1 < /dev/urandom | \
      fold -w$arg2 | \
      head -n1 \
      ) \
    )
  else
    output=$( \
      echo -n $( \
      tr -cd $arg1 < /dev/urandom | \
      fold -w$(jot -w %i -r 1 $arg2 $arg3) | \
      head -n1 \
      ) \
    )
  fi

  echo -n $(escape_string $output)
}