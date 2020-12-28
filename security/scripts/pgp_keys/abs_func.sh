#!/bin/sh

# Utility function for turning ints into unsigned ints (positive only).
# Usage:
# abs <integer>
function abs {
  if [ -z $1 ]
  then
    echo "abs: must provide number as argument"
    return 1
  elif [ $1 -lt 0 ]
  then
    echo $(($1 * -1))
  else
    echo $1
  fi
}