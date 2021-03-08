#!/bin/sh

# Name: run_install
# Desc: A method that executes a sequence of installation commands, as defined by the `update_instructions`
#       method found in /etc/profile.d/install_lib.sh, in a manner that prevents race conditions.

run_install() {
  local INSTRUCTION_SET_LIST=
  local OUTPUT_MODE=-1
  local FIRST_RUN=1
  local PROC_ID=

  # # Section 1 - Validation of Arguments - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  for OPT in "$@"; do # Iterate over every incoming argument.
    case $OPT in      # Check the value of each argument.
      -Q|--quiet)     # Silent running flag found.
        [ $OUTPUT_MODE -eq -1 ] && OUTPUT_MODE=0  # Latch the output mode to 0 only once.
        ;;
      -S|--status)    # Status message reporting flag found.
        [ $OUTPUT_MODE -eq -1 ] && OUTPUT_MODE=1  # Latch the output mode to 1 only once.
        ;;
      -V|--verbose)   # Verbose command reporting flag found.
        [ $OUTPUT_MODE -eq -1 ] && OUTPUT_MODE=2  # Latch the output mode to 2 only once.
        ;;
      *) # No flag found, possibly an instruction (*.sh) file.
        if [ ! -f "${OPT}" ]; then 
        # If the argument is not a path to a file that exists...
          echo -e "\033[7;33mERROR: File \"${OPT}\" does not exist!\033[0m"         # ...Error out.
          echo -e "\033[7;33mAborting Install.\033[0m"
          return 1    # Go no further, unknown argument.
        else
        # The argument is a path to a file that exists.
          if [ "$(echo ${OPT} | grep -o 'install_.*.sh')" == "" ]; then
          # If the correct filename format is not found...
            echo -e "\033[7;33mERROR: Wrong format for filename \"${OPT}\".\033[0m" # ...Error out.
            echo -e "\033[7;33mProper Format: \"install_<description_here>.sh\".\033[0m"
            echo -e "\033[7;33mAborting Install.\033[0m"
            return 1  # Go no further, incorrect filename.
          fi

          if [ -z "${INSTRUCTION_SET_LIST}" ]; then
          # If the list of instructions is empty...
            INSTRUCTION_SET_LIST="${OPT}" # ...Insert the first element.
          else
          # If the list of instructions is NOT empty...
            INSTRUCTION_SET_LIST="${INSTRUCTION_SET_LIST} ${OPT}" # ...Append the next element.
          fi
        fi
        ;;
    esac
  done

  # # Section 2 - Execution of Instructions - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  for INSTALL_SCRIPT in $INSTRUCTION_SET_LIST; do
    local DESCRIPTION=$( \
      echo $INSTALL_SCRIPT | \
      sed 's/^.*install_\(.*\)\.sh$/\1/g' \
    )

    local SKIP=$(. $INSTALL_SCRIPT && "check_skip_${DESCRIPTION}_install")

    if [ "${SKIP}" == "SKIP" ]; then
      echo -e "\033[7;33mSKIPPING: \"${DESCRIPTION}\"; already installed.\033[0m"
      # NOTE: We cannot call return here or we will cancel all instruction sets beyond this condition.
    else
      create_instructions_queue $OUTPUT_MODE
      [ ! $? -eq 0 ] && echo "ERROR: Call to \"create_instructions_queue ${OUTPUT_MODE}\" failed." && return 1

        . $INSTALL_SCRIPT

        $("add_${DESCRIPTION}_instructions_to_queue")
        [ ! $? -eq 0 ] && echo "ERROR: Call to \"add_${DESCRIPTION}_instructions_to_queue\" failed." && return 1

        [ $FIRST_RUN -eq 1 ] && export INSTALL_FUNC_NAME= || INSTALL_FUNC_NAME= # Prevent variable shadowing.

        while [ "${INSTALL_FUNC_NAME}" != "EOP" ]; do
          read_queued_instruction
          [ ! $? -eq 0 ] && echo "ERROR: Call to \"read_queued_instruction\" failed." && return 1

          if [ ! -z "${INSTALL_FUNC_NAME}" ]; then
            [ "${INSTALL_FUNC_NAME}" == "EOP" ] && continue # Halt once we have reached the end of instructions queue.

            $INSTALL_FUNC_NAME ${OUTPUT_MODE}
            PROC_ID=$( \
              ps -o pid,args | \
              grep -e ${INSTALL_FUNC_NAME} | \
              grep -v "grep" | \
              awk '{print $1}' | \
              sed 's/PID//' | \
              head -n1 \
            )
            [ ! -z "${PROC_ID}" ] && wait $PROC_ID || sleep 0.25s
            [ ! $? -eq 0 ] && echo "ERROR: Call to \"${INSTALL_FUNC_NAME}\" or \"wait ${PROC_ID}\" failed." && return 1
          fi
        done

      delete_instructions_queue
      [ ! $? -eq 0 ] && echo "ERROR: Call to \"delete_instructions_queue\" failed." && return 1
    fi
    FIRST_RUN=$(($FIRST_RUN + 1)) # Prevent variable shadowing of INSTALL_FUNC_NAME on line 74.
  done
}

# Instructions Queue CRUD Functions

create_instructions_queue() {
  local OPT=$1
  case $OPT in
    0)
      # completely silent * * * * * * * * * * * * * * * * * * *
      #
      exec 4>/dev/null  # stdout:   disabled  (Shell process)
      exec 5>/dev/null  # echo:     disabled  (Status command)
      exec 2>/dev/null  # stderr:   disabled
      set +v #          # verbose:  disabled
      ;;
    1)
      # status only * * * * * * * * * * * * * * * * * * * * * *
      #
      exec 4>/dev/null  # stdout:   disabled  (Shell process)
      exec 5>&1         # echo:     ENABLED   (Status command)
      exec 2>/dev/null  # stderr:   disabled
      set +v #          # verbose:  disabled
      ;;
    2)
      # verbose * * * * * * * * * * * * * * * * * * * * * * * *
      #
      exec 4>&1         # stdout:   ENABLED   (Shell process)
      exec 5>&1         # echo:     ENABLED   (Status command)
      exec 2>&1         # stderr:   ENABLED
      set -v #          # verbose:  ENABLED
      ;;
    *)
      # do nothing  * * * * * * * * * * * * * * * * * * * * * *
      echo " " >/dev/null
      ;;
  esac

  mkfifo /tmp/instructs 1>&4
  echo "Created pipe for instructions." 1>&5

  exec 3<> /tmp/instructs 1>&4
  echo "Executed file descriptor to unblock pipe." 1>&5

  unlink /tmp/instructs 1>&4
  echo "Unlinked the unblocked pipe." 1>&5

  $(echo ' ' 1>&3) 1>&4
  echo "Inserted blank space into unblocked pipe." 1>&5
}

read_queued_instruction() {
  read -u 3 INSTALL_FUNC_NAME
}

delete_instructions_queue() {
  exec 2>&1             # Restore stderr
  exec 3>&-             # Remove file descriptor 3
  exec 4>&-             # Remove file descriptor 4
  exec 5>&-             # Remove file descriptor 5
  rm -f /tmp/instructs  # Force deletion of pipe
  set +v #              # Cancel verbose mode
}