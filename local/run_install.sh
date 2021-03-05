#!/bin/sh

# Name: run_install
# Desc: A method that executes a sequence of installation commands.
# NOTE: Place in root path of project.

run_install() {
  local INSTALL_INSTRUCTIONS=$1

  if [ -z "${INSTALL_INSTRUCTIONS}" ]; then
    echo "ERROR: You must provide the path to an instruction file."
    return 1
  elif [ ! -f "${INSTALL_INSTRUCTIONS}" ]; then
    echo "ERROR: Instruction File \"${INSTALL_INSTRUCTIONS}\" Does Not Exist."
    return 1
  fi

  export CONTAINER_PATH=$(pwd)

  . $INSTALL_INSTRUCTIONS # Source the instructions we need to run.

  call_instructions
  if [ ! $? -eq 0 ]
  then
    echo "ERROR: Failed to call instructions"
    return 1            # Go no further, critical error.
  fi
}
