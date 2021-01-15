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
# run_install

run_install() {
  local OPT="${3}"
  local OUTPUT_MODE=1   # Default setting, status messages displayed only.
  local OUTPUT_OPT=     # String used to run commands in quiet/verbose mode.

  case $OPT in          # Check incoming arguments.
    -Q|--quiet)
      OUTPUT_MODE=0     # Strict silent mode, nothing displayed.
      OUTPUT_OPT=--quiet
      ;;
    -S|--status)
      #                 # Do nothing to default settings.
      ;;
    -V|--verbose)
      OUTPUT_MODE=2     # Strict verbose mode, everything displayed.
      OUTPUT_OPT=--verbose
      ;;
    *)
      echo "Bad Argument!"
      echo "Usage: $0 [-Q | --quiet | -S | --status | -V | --verbose]"
      echo "  -Q : Display no messages."
      echo "  -S : Display status messages only. (Default)"
      echo "  -V : Display all messages."
      return 1          # Go no further, user error.
      ;;
  esac

  if [ ! -f /etc/profile.d/install_lib.sh ]
  then
    echo "ERROR: Install Library File Missing: /etc/profile.d/install_lib.sh"
    return 1            # Go no further, install library missing.
  fi

  create_instructions   # Call install_lib method to load names of functions into pipe.
  if [ ! $? -eq 0 ]
  then
    echo "ERROR: Failed to call create_install_instructions"
    return 1            # Go no further, critical error.
  fi

  export INSTALL_FUNC_NAME=

  while [ "${INSTALL_FUNC_NAME}" != "EOF" ]
  do
    read -u3 INSTALL_FUNC_NAME                        # Read next instruction.
    [ "${INSTALL_FUNC_NAME}" == "EOF" ] && continue   # Conditionally halt if "EOF" found.
    $INSTALL_FUNC_NAME  # Run function whose name is read.
    PROC_ID=$(ps -o pid,args | grep "${INSTALL_FUNC_NAME}" | grep -v "grep" | awk '{print $1}')
    # Extract the PID from the last executed instruction using line above.
    wait PROC_ID        # Wait for the process to finish.
  done

  delete_instructions   # Remove the pipe once it's empty.
  if [ ! $? -eq 0 ]
  then
    echo "ERROR: failed to call delete_install_instructions"
    return 1
  fi
}

# run_install() {
#   local LEN=$("${1}"_len)
#   local ZEROS="${LEN}"
#   local CMD_SUCCESS=0
#   local LATCH=0
#   local n=1

#   if [ "${1}" == "cmd" ] || [ "${1}" == "init" ]
#   then
#     if [ ! -z "${2}" ]
#     then
#       # Initialize our sequence of completed commands.
#       export INSTALL_CMD_COMPLETED=0

#       while [ $n -le $LEN ]
#       do
#         # if [ $LATCH -eq 0 ] && [ $INSTALL_CMD_COMPLETED -lt $n ]
#         # then
#           # Run each command silently.
#           "${1}"_$(printf "%0${#ZEROS}d" "$n") & #>/dev/null 2>&1
#           CMD_SUCCESS=$?
#           wait
          
#           if [ $CMD_SUCCESS -gt 0 ]
#           then
#             echo "ERROR: $(sed "${n}q;d" ${2})"
#             return 1
#           # else
#           #   LATCH=1 # Prevent repeat of command(s)
#           #   echo "Latched to 1, we have completed ${INSTALL_CMD_COMPLETED} steps."
#           fi
#         # elif [ $LATCH -eq 1 ] && [ $INSTALL_CMD_COMPLETED -eq $n ]
#         # then
#           echo $(sed "${n}q;d" ${2})

#           n=$(($n + 1))
          
#         #   LATCH=0   # Allow next command to run.
#         # fi
#       done
#     fi
#   fi
# }
