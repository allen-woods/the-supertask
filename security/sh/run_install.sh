#!/bin/sh

# Name: run_install
# Desc: A method that executes a sequence of installation commands, such that
#       asynchronous code does not encounter race conditions and the granularity
#       of accuracy is increased while debugging errors.
#
# Note: The commands that are executed for a given install process are defined within
#       the `/etc/profile.d/install_<INSTALL_DESCRIPTION>.sh` shell script file; where
#       <INSTALL_DESCRIPTION> is a string describing the thing to be installed,
#       such as:
#       install_openssl.sh  = openssl
#       install_pgp.sh      = pgp
#       install_tls.sh      = tls

export INSTRUCT_PATH=/tmp/instructs

run_install() {
  local INSTRUCTION_SET_LIST=
  local OUTPUT_MODE=-1
  local HARD_STOP=0
  local FIRST_RUN=1
  local PROC_ID=

  # TODO:
  # Use of file descriptors inside of Docker containers (specifically 4 and 5)
  # are throwing errors. Due to this, as well as a security flaw surrounding
  # file descriptors inside of containers, we need to sunset the use of file
  # descriptors. Instead:
  #
  #   * Use $OUTPUT_MODE to tell install functions to use -q or -v equivalents.
  #   * Assign RUN_INSTALL_PRETTY_<STR> values from inside install functions.
  #   * Control whether messages are displayed within run_install.
  #
  # This represents a massive rewrite to a lot of functions, but will function
  # as desired in the original design.
  #
  # Lesson to be learned here is: Don't Re-Invent the Wheel!

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

    local SKIP=$(check_skip_${DESCRIPTION}_install)

    if [ "${SKIP}" == "SKIP" ]; then
      echo -e "\033[7;33mSKIPPING: \"${DESCRIPTION}\"; already installed.\033[0m"
      # NOTE: We cannot call return here or we will cancel all instruction sets beyond this condition.
    else
      # # # # # CRUD: Create
      create_instructions_queue
      # # # # #
      [ ! $? -eq 0 ] && echo "ERROR: Call to \"create_instructions_queue ${OUTPUT_MODE}\" failed." && HARD_STOP=1 && break

        $("add_${DESCRIPTION}_instructions_to_queue")
        [ ! $? -eq 0 ] && echo "ERROR: Call to \"add_${DESCRIPTION}_instructions_to_queue\" failed." && HARD_STOP=1 && break

        [ $FIRST_RUN -eq 1 ] && export INSTALL_FUNC_NAME= || INSTALL_FUNC_NAME= # Prevent variable shadowing.

        while [ "${INSTALL_FUNC_NAME}" != "EOP" ]; do
          # # # # # CRUD: Read
          read_queued_instruction
          # # # # #
          [ ! $? -eq 0 ] && echo "ERROR: Call to \"read_queued_instruction\" failed." && HARD_STOP=1 && break

          if [ ! -z "${INSTALL_FUNC_NAME}" ]; then
            [ "${INSTALL_FUNC_NAME}" == "EOP" ] && continue # Halt once we have reached the end of instructions queue.
            
            # Only allow verbose mode to show command output.
            [ $OUTPUT_MODE -eq 2 ] && \
            $INSTALL_FUNC_NAME $OUTPUT_MODE || \
            $INSTALL_FUNC_NAME $OUTPUT_MODE >/dev/null 2>&1
            # Capture the PID to allow for `wait` command.
            PROC_ID=$( \
              ps -o pid,args | \
              grep -e ${INSTALL_FUNC_NAME} | \
              grep -v "grep" | \
              awk '{print $1}' | \
              sed 's/PID//' | \
              head -n1 \
            )
            [ ! -z "${PROC_ID}" ] && wait $PROC_ID || sleep 0.25s
            [ ! $? -eq 0 ] && echo -e "\033[7;33mERROR:\033[7;31m Call to \"${INSTALL_FUNC_NAME}\" or \"wait ${PROC_ID}\" failed.\033[0m" && HARD_STOP=1 && break
          fi
        done
        [ $HARD_STOP -eq 1 ] && break; # Halt iterations completely after critical error.
      # # # # # CRUD: Delete
      delete_instructions_queue
      # # # # #
      [ ! $? -eq 0 ] && echo "ERROR: Call to \"delete_instructions_queue\" failed." && HARD_STOP=1 && break
    fi
    FIRST_RUN=$(($FIRST_RUN + 1)) # Prevent variable shadowing of INSTALL_FUNC_NAME on line 74.
  done
  [ $HARD_STOP -eq 1 ] && return 1 # Something went really wrong, shut everything down.
}

# Instructions Queue CRUD Functions

create_instructions_queue() {
  # local OPT=$1
  # case $OPT in
  #   0)
  #     # completely silent * * * * * * * * * * * * * * * * * * *
  #     #
  #     exec 4>/dev/null  # stdout:   disabled  (Shell process)
  #     exec 5>/dev/null  # echo:     disabled  (Status command)
  #     exec 2>/dev/null  # stderr:   disabled
  #     ;;
  #   1)
  #     # status only * * * * * * * * * * * * * * * * * * * * * *
  #     #
  #     exec 4>/dev/null  # stdout:   disabled  (Shell process)
  #     exec 5>&1         # echo:     ENABLED   (Status command)
  #     exec 2>/dev/null  # stderr:   disabled
  #     ;;
  #   2)
  #     # verbose * * * * * * * * * * * * * * * * * * * * * * * *
  #     #
  #     exec 4>&1         # stdout:   ENABLED   (Shell process)
  #     exec 5>&1         # echo:     ENABLED   (Status command)
  #     exec 2>&1         # stderr:   ENABLED
  #     ;;
  #   *)
  #     # do nothing  * * * * * * * * * * * * * * * * * * * * * *
  #     echo " " >/dev/null
  #     ;;
  # esac

  # We can't run `pretty` inside of an image build process,
  # only during a docker exec -it or docker run -it command.
  # So, we approximate its function here with some hard-coded
  # echoes.

  echo -e -n "\033[1;37m\033[45m INIT: Creating Pipe for Instructions                 "
  [ ! -d $INSTRUCT_PATH ] && mkfifo $INSTRUCT_PATH
  [ $? -eq 0 ] && \
  echo -e "\033[1;37m\033[42m PASSED! \033[0m" || \
  echo -e "\033[1;37m\033[41m FAILED. \033[0m" 

  echo -e -n "\033[1;37m\033[45m INIT: Executing File Descriptor to Unblock Pipe      "
  exec 3<> $INSTRUCT_PATH
  [ $? -eq 0 ] && \
  echo -e "\033[1;37m\033[42m PASSED! \033[0m" || \
  echo -e "\033[1;37m\033[41m FAILED. \033[0m" 

  echo -e -n "\033[1;37m\033[45m INIT: Unlinking the Unblocked Pipe                   "
  unlink $INSTRUCT_PATH
  [ $? -eq 0 ] && \
  echo -e "\033[1;37m\033[42m PASSED! \033[0m" || \
  echo -e "\033[1;37m\033[41m FAILED. \033[0m" 

  echo -e -n "\033[1;37m\033[45m INIT: Inserting Blank Space into Unblocked Pipe      "
  $(echo ' ' 1>&3)
  [ $? -eq 0 ] && \
  echo -e "\033[1;37m\033[42m PASSED! \033[0m" || \
  echo -e "\033[1;37m\033[41m FAILED. \033[0m" 
}

read_queued_instruction() {
  read -u 3 INSTALL_FUNC_NAME
}

delete_instructions_queue() {
  exec 2>&1 # Restore stderr
  exec 3>&-
  exec 4>&-
  exec 5>&-
  [ -d $INSTRUCT_PATH ] && rm -f $INSTRUCT_PATH
  unset INSTRUCT_PATH
}