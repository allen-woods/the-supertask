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
#
# run_install install_prefix
#
run_install() {
  local LEN=$("${1}"_len)
  local ZEROS="${LEN}"
  local CMD_SUCCESS=0
  local LATCH=0
  local n=1

  if [ "${1}" == "cmd" ] || [ "${1}" == "init" ]
  then
    if [ ! -z "${2}" ]
    then
      # Initialize our sequence of completed commands.
      export INSTALL_CMD_COMPLETED=0

      while [ $n -le $LEN ]
      do
        # if [ $LATCH -eq 0 ] && [ $INSTALL_CMD_COMPLETED -lt $n ]
        # then
          # Run each command silently.
          "${1}"_$(printf "%0${#ZEROS}d" "$n") & #>/dev/null 2>&1
          CMD_SUCCESS=$?
          wait
          
          if [ $CMD_SUCCESS -gt 0 ]
          then
            echo "ERROR: $(sed "${n}q;d" ${2})"
            return 1
          # else
          #   LATCH=1 # Prevent repeat of command(s)
          #   echo "Latched to 1, we have completed ${INSTALL_CMD_COMPLETED} steps."
          fi
        # elif [ $LATCH -eq 1 ] && [ $INSTALL_CMD_COMPLETED -eq $n ]
        # then
          echo $(sed "${n}q;d" ${2})

          n=$(($n + 1))
          
        #   LATCH=0   # Allow next command to run.
        # fi
      done
    fi
  fi
}
