#!/bin/sh

# Name: run_install
# Desc: A method that executes a sequence of installation commands, as defined by the `update_instructions`
#       method found in /etc/profile.d/install_lib.sh, in a manner that prevents race conditions.

run_install() {
  local OPT=$1
  local OUTPUT_MODE=1   # Default setting, status messages displayed only.
  local PROC_ID=        # Variable for capturing PID of installation function(s).

  case $OPT in          # Check incoming arguments.
    -Q|--quiet)
      OUTPUT_MODE=0     # Strict silent mode, nothing displayed.
      ;;
    -S|--status)
      #                 # Do nothing to default settings.
      ;;
    -V|--verbose)
      OUTPUT_MODE=2     # Strict verbose mode, everything displayed.
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

  if [ "$(check_skip_install)" == "SKIP" ]
  then
    echo "SKIPPING: Already installed."
    return 0            # Go no further, already installed.
  fi

  # NOTE: We may not need to load the OpenSSL alias in advance of purpose-built scripts.
  #       We will be building the aes-wrap enabled OpenSSL, then using it to create pgp data and a certificate chain.
  #
  # [ -f $HOME/.shrc ] && [ -z "${OPENSSL_V111}" ] && . $HOME/.shrc # If the SHRC file exists and the alias for OpenSSL is undefined,
  #                                                                 # source the SHRC file to create the alias for OpenSSL.

  create_instructions $OUTPUT_MODE # Call install_lib method to create pipe where function names are stored.
  if [ ! $? -eq 0 ]
  then
    echo "ERROR: Failed to call create_instructions"
    return 1            # Go no further, critical error.
  fi

  update_instructions   # Call install_lib method to store function names in pipe.
  if [ ! $? -eq 0 ]
  then
    echo "ERROR: Failed to call update_instructions"
    return 1            # Go no further, critical error.
  fi

  export INSTALL_FUNC_NAME= # Environment variable to which read instruction is assigned.

  while [ "${INSTALL_FUNC_NAME}" != "EOP" ] # Loop as long as we haven't reached EOP. (End of Pipe)
  do
    read_instruction    # Read next instruction.
    if [ ! -z $INSTALL_FUNC_NAME ]
    then
      if [ ! $? -eq 0 ]
      then
        echo "ERROR: failed to call read_instruction"
        return 1        # Go no further, critical error.
      fi
      if [ "${INSTALL_FUNC_NAME}" == "EOP" ]
      then
        continue        # Conditionally halt if "EOP" found.
      fi
      $INSTALL_FUNC_NAME # Execute the instruction
      PROC_ID=$( \
        ps -o pid,args | \
        grep -e ${INSTALL_FUNC_NAME} | \
        grep -v "grep" | \
        awk '{print $1}' | \
        sed 's/PID//' | \
        head -n1 \
      ) #               # Extract PID of background process.
      if [ ! -z "${PROC_ID}" ]
      then
        wait $PROC_ID   # Wait for the process to finish (if there is one).
        sleep 0.25s
      fi
      if [ ! $? -eq 0 ]
      then
        echo "ERROR: ${INSTALL_FUNC_NAME} (or wait ${PROC_ID}) encountered a problem."
        return 1        # Go no further, unknown or unexpected error.
      fi
    fi
  done

  delete_instructions   # Remove the pipe once it's empty.
  if [ ! $? -eq 0 ]
  then
    echo "ERROR: failed to call delete_instructions"
    return 1            # Go no further, critical error.
  fi
}
