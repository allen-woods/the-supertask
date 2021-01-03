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
run_install_instructions() {
  local BASE_FILE=/init_apk.txt
  local INSTRUCT_FILE=/instructions.txt
  local STATUS_FILE=/instruction_messages.txt
  local CMD_LIST=$(printf '%s\n' "$(cat < ${BASE_FILE})" "$(cat < ${INSTRUCT_FILE})")
  local CMD_LIST_LEN=$(( $(wc -l < $BASE_FILE) + $(wc -l < $INSTRUCT_FILE) ))
  local LAST_CMD=0
  local STATUS=

  for ((n=1; n<=$CMD_LIST_LEN; n++)); do
    # Silence the output of the command.
    ( $(echo -n "${CMD_LIST}" | sed "${n}q;d") >/dev/null 2>&1 )
    STATUS=$(sed "${n}q;d" $STATUS_FILE)
    LAST_CMD=$?

    if [ $LAST_CMD -gt 0 ]
    then
      echo "ERROR: ${STATUS}"
      return 1
    fi
    
    [ ${#STATUS} -gt 0 ] && echo "${STATUS}" || echo "Done!"
    # Sleep here if loop causes race condition in file system.
  done
}
