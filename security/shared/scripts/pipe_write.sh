#!/bin/sh

# NOTE: pass incoming data in the form ''"${data}"''

# TODO:
# This function needs to be rewritten to operate more like a stream containing several heredocs.
# The way I plan on doing this is by prepending and appending EOFN, where N is the data insertion count.
# This way, more complex data can be stored in one place without the need of multiple pipes for clarity.
# Ideally, each EOF block would have a name. This could be achieved using EOFN_{name here}_ syntax.

# pipe_write --pipe=/desired_pipe_name --head=desired_data_name [--crud=create | --crud=update] --data="<data separated by spaces>"

function pipe_crud {
  # Declare local vars.
  local PIPE=
  local HEAD=
  local CRUD=
  local DATA=

  # Check incoming arguments.
  if [[ "${PIPE}" == "" || "${HEAD}" == "" || "${CRUD}" == "" || "${DATA}" == "" ]]
  then
    echo "Bad Argument(s)!"
    echo "Usage: $0 --pipe=<pipe_path> --head=<document_id> --crud=<crud_action> --data=\"<data=here>\""
    echo "" # Breathing space #################################################################################
    echo "  --pipe=<pipe_path>     : Path and filename of pipe."
    echo "  --head=<document_id>   : Identifier of target document for CRUD action."
    echo "  --crud=<crud_action>   : Crud action to perform on target document, as follows:"
    echo "" # Breathing space #################################################################################
    echo "                           create : Creates a new document with name document_id."
    echo "                           read   : Reads the document named document_id, as specified by --data."
    echo "                           update : Updates the document named document_id, as specified by --data."
    echo "                           delete : Deletes the document named document_id, as specified by --data."
    echo "" # Breathing space #################################################################################
    echo "  --data=\"<data=here>\" : Double-quoted, space delimited data, as follows:"
    echo "" # Breathing space #################################################################################
    echo "                           Create : variable=value"
    echo "                           Read   : variable (1)"
    echo "                           Update : variable=value *"
    echo "                           Delete : variable (1)"
    echo "" # Breathing space #################################################################################
    echo "                                  * NOTE: When updating with a new variable, that variable will be"
    echo "                                          appended to the contents of document named document_id."
    echo "" # Breathing space #################################################################################
    echo "                                  1 NOTE: To read or delete the entire document named document_id,"
    echo "                                          use --data=\"--\"."
    echo "" # Trailing white space ############################################################################
    return 1;
  fi

  # Parse our arguments.
  for OPT in "$@"
  do
    [[ "$(echo -n ${OPT} | grep -e --pipe=)" != "" ]] && PIPE=$(echo -n $OPT | sed 's/--pipe=\(.*\)/\1/')
    [[ "$(echo -n ${OPT} | grep -e --head=)" != "" ]] && HEAD=$(echo -n $OPT | sed 's/--head=\(.*\)/\1/')
    [[ "$(echo -n ${OPT} | grep -e --crud=)" != "" ]] && CRUD=$(echo -n $OPT | sed 's/--crud=\(.*\)/\1/')
    [[ "$(echo -n ${OPT} | grep -e --data=)" != "" ]] && DATA="$(echo -n ${OPT} | sed 's/--data=\"\(.*\)\"/\1/')"
  done

  case $CRUD in
    create)
      if [ ! -p $PIPE ] # Nothing exists.
      then
        # The pipe does not yet exist, so create it.
        mkfifo $PIPE

        # Make the pipe non-blocking.
        exec 7<> $PIPE

        # Unlink the pipe to complete the non-blocking behavior.
        unlink $PIPE

        # Create the document and its data; since only one document in pipe, append EOF at the end.
        printf '%s\n' "BOF ${HEAD}" $DATA "EOF" > $PIPE
      else
        # if the head does not yet exist in pipe, create it and place the data into it.

      fi
      ;;
    read)
      # Read code here
      ;;
    update)
      # Update code here
      ;;
    delete)
      # Delete code here
      ;;
    *)
      # Handle bad argument here.
      ;;
  esac

  [ ! -p $PIPE ] && mkfifo $PIPE

}

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