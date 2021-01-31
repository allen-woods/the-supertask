#!/bin/sh

pipe_crud() {
  local PIPE=   #               # The name of the pipe.
  local DOC_ID= #               # The descriptor of the current document.
  local CRUD=   #               # The action to perform on the current document.
  local DATA=   #               # The variables container in the current document.
  local HOOK=   #               # Optional behavior to perform after CRUD action(s).
  local SYNC=   #               # A variable used as a data store between CRUD actions.

  for OPT in "$@"               # Parse our arguments.
  do
    local illegal_arg=1         # Presume there is an illegal argument.

    if [ "$(echo ${OPT} | grep -e --pipe=)" != "" ]      # If grep matches the pattern --pipe=
    then
      PIPE="$(echo ${OPT} | sed 's/--pipe=\(.*\)/\1/')"  # Parse the pipe name past the equal sign and assign it to PIPE
      illegal_arg=0             #                           # This argument is legal
    fi

    if [ "$(echo ${OPT} | grep -e --doc-id=)" != "" ]       # If grep matches the pattern --doc-id=
    then
      DOC_ID="$(echo ${OPT} | sed 's/--doc-id=\(.*\)/\1/')" # Parse the document id past the equal sign and assign it to DO_ID
      illegal_arg=0             #                           # This argument is legal
    fi

    if [ "$(echo ${OPT} | grep -e --crud=)" != "" ]         # If grep matches the pattern --crud=
    then
      CRUD="$(echo ${OPT} | sed 's/--crud=\(.*\)/\1/')"     # Parse the crud action past the equal sign and assign it to RUD
      illegal_arg=0             #                           # This argument is legal
    fi

    if [ "$(echo ${OPT} | grep -e --data=)" != "" ]         # If grep matches the pattern --data=
    then
      DATA="$(echo ${OPT} | sed 's/--data=\(.*\)/\1/')"     # Parse the variable=value pair(s) past the equal sign and assign them to DATA
      illegal_arg=0             #                           # This argument is legal
    fi

    if [ "$(echo ${OPT} | grep -e --hook=)" != "" ]         # If grep matches the pattern --hook=
    then
      HOOK="$(echo ${OPT} | sed 's/--hook=\(.*\)/\1/')"     # Parse the hook keyword past the equal sign and assign it to HOOK
      illegal_arg=0             #                           # This argument is legal
    fi

    if [ ! $illegal_arg -eq 0 ] # If the argument is not any of the legal options
    then
      pipe_crud_usage           # Show utility usage
      return 1                  # Go no further, user error
    fi
  done

  if [ -z "${PIPE}" ] || [ -z "${DOC_ID}" ] || [ -z "${CRUD}" ] || [ -z "${DATA}" ] # If any of the required arguments are blank
  then
    pipe_crud_usage             # Show utility usage
    return 1                    # Go no further, user error
  fi
  case $CRUD in
    create) ################################################################# CRUD Action: Create
      if [ ! -p $PIPE ]               # no pipe
      then
        if [ "${PIPE}" == "--" ]      # no pipe name
        then
          echo "ERROR: Must provide name of pipe." # error out
          return 1
        else    # yes pipe name
          if [ "${DOC_ID}" == "--" ]  # no doc id
          then
            echo "ERROR: Must provide name of document."  # error out
            return 1
          else  # yes doc id - (could be iterator)
            if [ "${DATA}" == "--" ]  # no data
            then
              echo "ERROR: Must provide document data."   # error out
              return 1
            else # yes data - (could be iterator)
              mkfifo $PIPE            # Create PIPE if it doesn't exist.

              ( \
                printf '%s\n' "BOF=${DOC_ID}" \
                $DATA \
                "EOF=${DOC_ID}" \
                'EOP' ' ' >> $PIPE & \
              ) # put doc containing data in pipe
            fi
          fi
        fi
      else      # yes pipe
        if [ "${DOC_ID}" == "--" ]        # no doc id
        then
          echo "ERROR: Must provide name of document."  # error out
          return 1  # Go no further, user error
        else        # yes doc id
          read_lines_into_pipe_crud_sync $PIPE
          local duplicate_exists=1

          if [ -z "$(echo "${SYNC}" | grep -e $DOC_ID)" ]
          then 
            duplicate_exists=0
          fi

          if [ $duplicate_exists -eq 1 ]  # yes doc found
          then
            echo "ERROR: document name already exists." # error out
            return 1
          else      # no doc found
            if [ "${DATA}" == "--" ]      # no data
            then
              echo "ERROR: Must provide document data." # error out
              return 1
            else    # yes data
              ( \
                printf '%s\n' $SYNC \
                "BOF=${DOC_ID}" \
                $DATA \
                "EOF=${DOC_ID}" \
                'EOP' ' ' >> $PIPE & \
              )     # append doc containing data to pipe
              SYNC= # Empty SYNC once action completed.
            fi
          fi
        fi
      fi
      ;;
    read) ################################################################### CRUD Action: Read
      if [ ! -p $PIPE ] # no pipe
      then
        echo "ERROR: Pipe \"${PIPE}\" does not exist."  # error out
        return 1  # Go no further, file system error
      else        # yes pipe
        if [ "${DOC_ID}" == "--" ]  # no doc id
        then
          if [ "${DATA}" == "--" ]  # no data
          then
            read_lines_into_pipe_crud_sync $PIPE        # capture a copy of pipe's contents
            printf '%s\n' $SYNC     # print entire pipe

            # TODO: conditionally restore based on HOOK

            ( \
              printf '%s\n' $SYNC \
              'EOP' ' ' >> $PIPE & \
            )     # restore contents of pipe
            SYNC= # empty sync when finished
          fi      # yes data, do nothing
        else      # yes doc id - (could be iterator)
          read_lines_into_pipe_crud_sync $PIPE          # capture a copy of pipe's contents
          if [ -z "$(echo ${SYNC} | grep -e ${DOC_ID})" ] # no doc found
          then
            ( \
              printf '%s\n' $SYNC \
              'EOP' ' ' >> $PIPE & \
            ) # restore contents of pipe before return 1
            SYNC= # empty sync when finished
            echo "ERROR: Document ID \"${DOC_ID}\" not found." # error out
            return 1
          else # yes doc found
            local read_doc_contents="$(echo ${SYNC} | sed 's/\(BOF='"${DOC_ID}"'\) \(.*\) \(EOF='"${DOC_ID}"'\)/\1 \2 \3/')"
            if [ "${DATA}" == "--" ] # no data
            then
              printf '%s\n' $read_doc_contents # print entire doc

              # TODO: conditionally restore based on HOOK

              ( \
                printf '%s\n' $SYNC \
                'EOP' ' ' >> $PIPE & \
              ) # restore contents of pipe
              SYNC= # empty sync when finished
            else # yes data - (could be iterator)
              local read_req_data=
              for read_var_name in $DATA # look for data by name
              do
                local clean_var_name="$(echo ${read_var_name} | sed 's/[[:punct:]]//g')"
                local read_req_data_match="$( \
                  echo ${read_doc_contents} | \
                  sed 's/.*\('"${clean_var_name}"'\)=\(.*\),.*/\2/' | \
                  cut -d ' ' -f1 | \
                  sed 's/,$//g' \
                )"

                if [ ! -z "${read_req_data_match}" ] && \
                [ ! -z "$(echo ${read_doc_contents} | grep -o ${read_req_data_match})" ]
                then
                  if [ -z "${read_req_data}" ]
                  then
                    read_req_data="${read_req_data_match}"
                  else
                    read_req_data="${read_req_data} ${read_req_data_match}"
                  fi
                else

                  # TODO: conditionally restore based on HOOK

                  ( \
                    printf '%s\n' $SYNC \
                    'EOP' ' ' >> $PIPE & \
                  ) # restore contents of pipe before return 1
                  SYNC= # empty sync when finished
                  echo "ERROR: Data \"${clean_var_name}\" does not exist."  # error out
                  return 1
                fi
              done
              echo $read_req_data # print only data

              # TODO: conditionally restore based on HOOK

              ( \
                printf '%s\n' $SYNC \
                'EOP' ' ' >> $PIPE & \
              ) # restore contents of pipe before return 1
              SYNC= # empty sync when finished
            fi
          fi
        fi
      fi
      ;;
    update) ################################################################# CRUD Action: Update
      if [ ! -p $PIPE ] # no pipe
      then
        echo "ERROR: Pipe \"${PIPE}\" does not exist." # error out
        return 1
      else # yes pipe
        if [ "${DOC_ID}" == "--" ] # no doc id
        then
          echo "ERROR: Must provide name of document." # error out
          return 1
        else # yes doc id - (could be iterator)
          read_lines_into_pipe_crud_sync $PIPE
          if [ -z "$(echo ${SYNC} | grep -o ${DOC_ID})" ] # no doc found
          then
            ( \
              printf '%s\n' $SYNC \
              'EOP' ' ' >> $PIPE & \
            ) # restore contents of pipe before return 1
            SYNC= # empty sync when finished
            echo "ERROR: Document \"${DOC_ID}\" does not exist or was deleted." # error out
            return 1
          else # yes doc found
            if [ "${DATA}" == "--" ] # no data
            then
              ( \
                printf '%s\n' $SYNC \
                'EOP' ' ' >> $PIPE & \
              ) # restore contents of pipe before return 1
              SYNC= # empty sync when finished
              echo "ERROR: Must provide document data." # error out
              return 1
            else # yes data - (could be iterator)
              local update_req_data="$(echo ${SYNC} | sed 's/\(BOF='"${DOC_ID}"'\) \(.*\) \(EOF='"${DOC_ID}"'\)/\2/')"
              echo "update_req_data: ${update_req_data}"
              for update_var_val_pair in $DATA # look for data
              do
                local update_var_name="$(echo ${update_var_val_pair} | sed 's/\(.*\)=\(.*\),/\1/')"
                local update_val_data="$(echo ${update_var_val_pair} | sed 's/\(.*\)=\(.*\),/\2/')"
                local update_req_data_match="$( \
                  echo ${update_req_data} | \
                  grep -o ${update_var_name}
                )"

                if [ ! -z "${update_req_data_match}" ]
                then
                  local old_data=
                  for old_item in $update_req_data
                  do
                    if [ ! -z "$(echo ${old_item} | grep -o ${update_var_name})" ]
                    then
                      old_data="$(echo ${old_item} | cut -d '=' -f2 | sed 's/,$//g')"
                      break
                    fi
                  done
                  update_req_data="$( \
                    echo ${update_req_data} | \
                    sed 's/'"${old_data}"'/'"${update_val_data}"'/' \
                  )"
                else
                  update_req_data="${update_req_data} ${update_var_val_pair}"
                fi
              done
              SYNC="$(echo ${SYNC} | sed 's/\(BOF='"${DOC_ID}"'\) \(.*\) \(EOF='"${DOC_ID}"'\)/\1 '"${update_req_data}"' \3/')"

              # TODO: conditionally restore based on HOOK

              ( \
                printf '%s\n' $SYNC \
                'EOP' ' ' >> $PIPE & \
              ) # restore contents of pipe
              SYNC= # empty sync when finished
            fi
          fi
        fi
      fi
      ;;
    delete) ################################################################# CRUD Action: Delete
      if [ ! -p $PIPE ] # no pipe
      then
        echo "ERROR: Pipe ${PIPE} does not exist or was already deleted." # error out
        return 1 # Go no further, file system error
      else # yes pipe
        if [ "${DOC_ID}" == "--" ] # no doc id
        then
          if [ "${DATA}" == "--" ] # no data
          then
            rm -f $PIPE # delete entire pipe
          fi # yes data, do nothing
        else # yes doc id - (could be iterator)
          read_lines_into_pipe_crud_sync $PIPE

          if [ -z "$(echo ${SYNC} | grep -e ${DOC_ID})" ] # no doc found
          then
            ( \
              printf '%s\n' $SYNC \
              'EOP' ' ' >> $PIPE & \
            )
            SYNC=
            echo "ERROR: Document ID ${DOC_ID} does not exist or was deleted." # error out
            return 1 # Go no further, user error
          fi

          local doc_bof_found=0
          local doc_eof_found=0
          local doc_item_found=0
          local doc_items_exist=0
          local REMAINING=

          for delete_sync in $SYNC
          do
            if [ ! -z "$(echo ${delete_sync} | grep -e BOF=${DOC_ID})" ] && [ $doc_bof_found -eq 0 ]
            then
              doc_bof_found=1
            elif [ ! -z "$(echo ${delete_sync} | grep -e EOF=${DOC_ID})" ] && [ $doc_eof_found -eq 0 ]
            then
              doc_eof_found=1
            elif [ $doc_bof_found -eq 1 ] && [ $doc_eof_found -eq 1 ]
            then
              doc_bof_found=0
              doc_eof_found=0
            fi

            if [ ! $doc_bof_found -eq 1 ]
            then
              if [ "${DATA}" == "--" ]
              then
                if [ -z "${REMAINING}" ]
                then
                  REMAINING="${delete_sync}"
                else
                  REMAINING="${REMAINING} ${delete_sync}"
                fi
              fi
            elif [ $doc_bof_found -eq 1 ]
            then
              if [ ! "${DATA}" == "--" ]
              then
                doc_item_found=0
                for delete_item in $DATA
                do
                  if [ ! -z "$(echo ${delete_sync} | grep -e ${delete_item})" ] && [ $doc_item_found -eq 0 ]
                  then
                    doc_item_found=1
                    if [ $doc_items_exist -eq 0 ]
                    then
                      doc_items_exist=1
                    fi
                    break
                  fi

                  # if [ ! $doc_items_exist -eq 1 ] && [ $doc_eof_found -eq 1 ]
                  # then
                  #   ( \
                  #     printf '%s\n' $SYNC \
                  #     'EOP' ' ' >> $PIPE & \
                  #   )
                  #   SYNC=
                  #   echo "ERROR: Document item ${delete_item} does not exist or was deleted." # error out
                  #   return 1 # Go no further, user error
                  # fi
                done

                if [ ! $doc_item_found -eq 1 ]
                then
                  if [ -z "${REMAINING}" ]
                  then
                    REMAINING="${delete_sync}"
                  else
                    REMAINING="${REMAINING} ${delete_sync}"
                  fi
                fi
              fi
            fi
          done

          SYNC="${REMAINING}"

          ( \
            printf '%s\n' $SYNC \
            'EOP' ' ' >> $PIPE & \
          )
          SYNC=
        fi
      fi
      ;;
    *)
      # Handle bad argument value here.
      pipe_crud_usage
      return 1
      ;;
  esac
}

read_lines_into_pipe_crud_sync() {
  while IFS= read -r LINE
  do
    if [ -z "${SYNC}" ]
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
  done < "${1}"
}

pipe_crud_usage() {
  echo "Bad Argument(s)"
  echo "Usage: $0 --pipe=<path> --doc-id=<id> --crud=<action> --data=\"<var=val,>\" [--hook=<option>]"
  echo "" # Breathing space #################################################################################
  echo "  --pipe=<path>          : Path and filename of pipe."
  echo "  --doc-id=<id>          : Identifier of target document for CRUD action."
  echo "  --crud=<action>        : Crud action to perform on target document, as follows:"
  echo "" # Breathing space #################################################################################
  echo "                           create : Creates a new document with name document_id."
  echo "                           read   : Reads the document named document_id, as specified by --data."
  echo "                           update : Updates the document named document_id, as specified by --data."
  echo "                           delete : Deletes the document named document_id, as specified by --data."
  echo "" # Breathing space #################################################################################
  echo "  --data=\"<var=val,>\"  : Double-quoted, space delimited data with trailing commas, as follows:"
  echo "" # Breathing space #################################################################################
  echo "                           Create : variable=value, variable=value,"
  echo "                           Read   : variable, variable, (1)"
  echo "                           Update : variable=value, variable=value, (*)"
  echo "                           Delete : variable, variable, (1)"
  echo "" # Breathing space #################################################################################
  echo "                                  * NOTE: When updating with a new variable, that variable will be"
  echo "                                          appended to the contents of document named id."
  echo "" # Breathing space #################################################################################
  echo "                                  1 NOTE: To read or delete the entire document named id, use"
  echo "                                          --data=\"--\"."
  echo "" # Breathing space #################################################################################
  echo "  --hook=<option>        : An optional behavior to perform along with CRUD action(s), as follows:"
  echo "" # Breathing space #################################################################################
  echo "                           This feature is not yet implemented."
  echo "" # Trailing white space ############################################################################
}