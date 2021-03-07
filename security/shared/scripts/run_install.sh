#!/bin/sh

# Name: run_install
# Desc: A method that executes a sequence of installation commands, as defined by the `update_instructions`
#       method found in /etc/profile.d/install_lib.sh, in a manner that prevents race conditions.

run_install() {
  local INSTRUCTION_SET_LIST=
  local OUTPUT_MODE=-1
  local PROC_ID=

  for OPT in "$@"; do
    case $OPT in
      -Q|--quiet)
        [ $OUTPUT_MODE -eq -1 ] && OUTPUT_MODE=0
        ;;
      -M|--messages)
        [ $OUTPUT_MODE -eq -1 ] && OUTPUT_MODE=1
        ;;
      -V|--verbose)
        [ $OUTPUT_MODE -eq -1 ] && OUTPUT_MODE=2
        ;;
      *)
        if [ ! -f "${OPT}" ]; then
          echo -e "\033[7;33mERROR: File \"${OPT}\" does not exist!\033[0m"
          echo -e "\033[7;33mAborting Install.\033[0m"
          return 1
        else
          if [ "$(echo ${OPT} | grep -o 'install_.*.sh')" == "" ]; then
            echo -e "\033[7;33mERROR: Wrong format for filename \"${OPT}\".\033[0m"
            echo -e "\033[7;33mProper Format: \"install_<description_here>.sh\".\033[0m"
            echo -e "\033[7;33mAborting Install.\033[0m"
            return 1
          fi

          if [ -z "${INSTRUCTION_SET_LIST}" ]; then
            INSTRUCTION_SET_LIST="${OPT}"
          else
            INSTRUCTION_SET_LIST="${INSTRUCTION_SET_LIST} ${OPT}"
          fi
        fi
        ;;
    esac
  done

  for INSTALL_SCRIPT in "${INSTRUCTION_SET_LIST}"; do
    local DESCRIPTION=$(echo $INSTALL_SCRIPT | sed 's/^[^ ]\{0,\}install_\(.*\).sh$/\1/g')
    . $INSTALL_SCRIPT
    if [ "$(check_skip_${DESCRIPTION}_install)" == "SKIP" ]; then
      echo -e "\033[7;33mSKIPPING: ${DESCRIPTION} already installed.\033[0m"
    else
      # Normal behavior.
    fi
  done

  # # # Below there be dragons # # #
  
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
