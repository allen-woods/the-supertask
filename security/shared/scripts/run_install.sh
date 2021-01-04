#!/bin/sh

# This script concatenates two files that contain instructions for the container,
# then executes instructions line by line.
#
# `init_apk.txt`: patches apk repos to the latest stable version of Alpine,
# then installs static tools for installing packages before upgrading the OS.
#
# `instructions.txt`: first adds dependencies for the image, then lists
# the shell script functions that must be executed.
#
# For loop: executes each line of the concatenated files unless a given line throws
# an error by returning 1.
#
# return of 1: function will pretty print that an error occurred and the contents
# of the line that failed to run.
run_install() {
  local len=$("${1}"_len)
  local zeros="${len}"
  local CMD_SUCCESS=0
  local n=1

  if [ "${1}" == "cmd" ] || [ "${1}" == "init" ]
  then
    if [ ! -z "${2}" ]
    then
      while [ "$n" -le $len ]
      do
        # Run each command silently.
        "${1}"_$(printf "%0${#zeros}d" "$n") >/dev/null 2>&1
        CMD_SUCCESS=$?

        if [ $CMD_SUCCESS -gt 0 ]
        then
          echo "ERROR: $(sed "${n}q;d" ${2})"
          return 1
        fi
        
        echo $(sed "${n}q;d" ${2})

        n=$(($n + 1))
        sleep 0.05s
      done
    fi
  fi
}
