#!/bin/sh

# Name: run_install
# Desc: A method that executes a sequence of installation commands
#       as defined by the `create_instructions` method found in
#       /etc/profile.d/install_lib.sh

run_install() {
  local OPT="${1}"
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

  [ ! -f /etc/profile.d/install_lib.sh ] && echo "ERROR: \
  Install Library File Missing: /etc/profile.d/install_lib.sh"; \
  return 1;             # Go no further, install library missing.

  create_instructions   # Call install_lib method to load names of functions into pipe.
  [ ! $? -eq 0 ] && echo "ERROR: Failed to call create_instructions"; \
  return 1;             # Go no further, critical error.

  export INSTALL_FUNC_NAME= # Environment variable to which read instruction is assigned.

  while [ "${INSTALL_FUNC_NAME}" != "EOF" ]
  do
    read_instruction    # Read next instruction.
    [ ! $? -eq 0 ] && echo "ERROR: failed to call read_instruction"; \
    return 1;           # Go no further, critical error.

    [ "${INSTALL_FUNC_NAME}" == "EOF" ] && continue # Conditionally halt if "EOF" found.
    #################################################################
    # TODO: add support for "quiet", "status", and "verbose" modes. #
    #################################################################
    $INSTALL_FUNC_NAME &# Run function whose name is read in background.
    PROC_ID=$( \
      ps -o pid,args | \
      grep "${INSTALL_FUNC_NAME}" | \
      grep -v "grep" | \
      awk '{print $1}' \
    ) #                 # Extract PID of background process.
    wait PROC_ID        # Wait for the process to finish.
    [ ! $? -eq 0 ] && echo "ERROR: ${INSTALL_FUNC_NAME} (or wait ${PROC_ID}) encountered a problem."; \
    return 1;           # Go no further, unknown or unexpected error.
  done

  delete_instructions   # Remove the pipe once it's empty.
  [ ! $? -eq 0 ] && echo "ERROR: failed to call delete_instructions"; \
  return 1;             # Go no further, critical error.
}
