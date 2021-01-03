#!/bin/sh

echoHorizontalRule() {
  arg1=${1:-"--thick"}
  if [ "${arg1}" == "--thin" ]
  then
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  elif [ "${arg1}" == "--thick" ]
  then
    echo "==============================================================================="
  else
    echo "echoHorizontalRule: Unknown flag: ${arg1}"
    echo "Usage:"
    echo "echoHorizontalRule [--thin | --thick]"
    return 1
  fi
}