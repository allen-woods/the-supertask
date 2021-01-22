#!/bin/sh

pipe_crud()
( #             # Run in a subshell to prevent leaks.
  local PIPE=   #       # The name of the pipe.
  local DOC_ID= #       # The descriptor of the current document.
  local CRUD=   #       # The action to perform on the current document.
  local DATA=   #       # The variables container in the current document.
  local HOOK=   #       # Optional behavior to perform after CRUD action(s).

  local SYNC=   #       # A variable used as a data store between CRUD actions.

  for OPT in "$@"       # Parse our arguments.
  do
    local illegal_arg=1 # Presume there is an illegal argument.
    [[ "$(echo -n ${OPT} | grep -e --pipe=)" != "" ]] && PIPE=$(echo -n $OPT | sed 's/--pipe=\(.*\)/\1/') && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --doc-id=)" != "" ]] && DOC_ID=$(echo -n $OPT | sed 's/--doc-id=\(.*\)/\1/') && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --crud=)" != "" ]] && CRUD=$(echo -n $OPT | sed 's/--crud=\(.*\)/\1/') && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --data=)" != "" ]] && DATA="$(echo -n ${OPT} | sed 's/--data=\"\(.*\)\"/\1/')" && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --hook=)" != "" ]] && HOOK="$(echo -n ${OPT} | sed 's/--hook=\(.*\)/\1/')" && illegal_arg=0

    if [ ! $illegal_arg -eq 0 ]
    then
      usage #           # If we found an illegal argument, show usage and return 1.
      return 1
    fi
  done

  if [[ "${PIPE}" == "" || "${DOC_ID}" == "" || "${CRUD}" == "" || "${DATA}" == "" ]]
  then
    usage #             # If we didn't receive all required arguments, show usage and return 1.
    return 1
  fi

  case $CRUD in
    create) #                                                               # CRUD Action: Create
      if [ ! -p $PIPE ]
      then
        mkfifo -m 0600 $PIPE #                                              # Create PIPE if it doesn't exist.
        ( printf '%s\n' "BOF=${DOC_ID}" $DATA 'EOF' 'EOP' ' ' >> $PIPE & )  # Place DOC_ID containing DATA into PIPE.
      else
        read_lines_into_sync

        if [ "$(echo -n ${SYNC} | grep -e ${DOC_ID})" == "" ] #             # Place DOC_ID into PIPE if no duplicate.
        then
          (
            printf '%s\n' $SYNC "BOF=${DOC_ID}" $DATA 'EOF' \
            'EOP' ' ' >> $PIPE & \
          )
          SYNC= #       # Empty SYNC once action completed.
        fi
      fi
      ;;
    read) #                                                                 # CRUD Action: Read
      # Read code here
      ;;
    update) #                                                               # CRUD Action: Update
      read_lines_into_sync

      if [ "$(echo -n ${SYNC} | grep -e ${DOC_ID})" != "" ]
      then
        # Update DATA in SYNC.
        # Place DATA into PIPE.
        SYNC=
      fi
      ;;
    delete) #                                                               # CRUD Action: Delete
      # Delete code here
      ;;
    *)
      # Handle bad argument value here.
      usage
      return 1
      ;;
  esac

  read_lines_into_sync() {
    while IFS= read -r LINE
    do
      if [ -z $SYNC ]
      then
        SYNC="${LINE}"
      else
        if [ "${LINE}" == "EOP" ]
        then
          break
        else
          SYNC="${SYNC} ${LINE}"
        fi
      fi
    done < $PIPE
  }

  usage() {
    echo "Bad Argument(s)"
    echo "Usage: $0 --pipe=<path> --doc-id=<id> --crud=<action> --data=\"<var=val>\" [--hook=<option>]"
    echo "" # Breathing space #################################################################################
    echo "  --pipe=<pipe_path>     : Path and filename of pipe."
    echo "  --doc-id=<document_id> : Identifier of target document for CRUD action."
    echo "  --crud=<crud_action>   : Crud action to perform on target document, as follows:"
    echo "" # Breathing space #################################################################################
    echo "                           create : Creates a new document with name document_id."
    echo "                           read   : Reads the document named document_id, as specified by --data."
    echo "                           update : Updates the document named document_id, as specified by --data."
    echo "                           delete : Deletes the document named document_id, as specified by --data."
    echo "" # Breathing space #################################################################################
    echo "  --data=\"<var=val>\"   : Double-quoted, space delimited data, as follows:"
    echo "" # Breathing space #################################################################################
    echo "                           Create : variable=value"
    echo "                           Read   : variable (1)"
    echo "                           Update : variable=value (*)"
    echo "                           Delete : variable (1)"
    echo "" # Breathing space #################################################################################
    echo "                                  * NOTE: When updating with a new variable, that variable will be"
    echo "                                          appended to the contents of document named document_id."
    echo "" # Breathing space #################################################################################
    echo "                                  1 NOTE: To read or delete the entire document named document_id,"
    echo "                                          use --data=\"--\"."
    echo "" # Breathing space #################################################################################
    echo "  --hook=<option>        : An optional behavior to perform along with CRUD action(s), as follows:"
    echo "" # Breathing space #################################################################################
    echo "                           TBD."
    echo "" # Trailing white space ############################################################################
  }
)

# Old version below * * * * *

# function pipe_write {
#   local pipe=${1:-"test"}
#   local data=${2:-"the quick brown fox jumps over the lazy dog"}
#   local flag=${3:-"--append"}
#   local first_run=0
#   local sync=

#   if [ ! -p $pipe ]
#   then
#     # Create the pipe if it doesn't exist.
#     mkfifo $pipe
    
#     # Set `first_run` for proper data handling below.
#     first_run=1
#   fi

#   if [ $first_run -eq 0 ] && [ "${flag}" == "--overwrite" ]
#   then
#     # Empty the pipe completely, and silently.
#     ( ( echo ' ' >> $pipe & ) && echo "$(cat < ${pipe})" ) > /dev/null 2>&1
    
#     # Set `first_run` for proper data handling below.
#     first_run=1
#   fi

#   if [ $first_run -eq 0 ] && [[ -z $sync ]]
#   then
#     # If we are appending data, front-load contents of pipe.
#     sync=''"$(cat < ${pipe})"''
#   fi

#   for item in $data
#   do
#     if [ $first_run -eq 1 ]
#     then
#       # Pipe is empty, place first item into `sync`.
#       sync=''"${item}"''

#       # Unset `first_run` to indicate start of data collection.
#       first_run=0
#     else
#       # Data has collected at least one thing, append item to `sync`.
#       sync=''"$(printf "%s\n" ''"${sync}"'' ''"${item}"'')"''
#     fi
#   done

#   # Silently place contents of `sync` into pipe. 
#   ( echo ''"${sync}"'' > $pipe & )
# }