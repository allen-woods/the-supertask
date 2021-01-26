#!/bin/sh

pipe_crud()
( #             # Run in a subshell to prevent leaks.
  local PIPE=   #             # The name of the pipe.
  local DOC_ID= #             # The descriptor of the current document.
  local CRUD=   #             # The action to perform on the current document.
  local DATA=   #             # The variables container in the current document.
  local HOOK=   #             # Optional behavior to perform after CRUD action(s).
  local SYNC=   #             # A variable used as a data store between CRUD actions.
  for OPT in "$@"             # Parse our arguments.
  do
    local illegal_arg=1       # Presume there is an illegal argument.
    [[ "$(echo -n ${OPT} | grep -e --pipe=)" != "" ]] && PIPE=$(echo -n $OPT | sed 's/--pipe=\(.*\)/\1/') && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --doc-id=)" != "" ]] && DOC_ID=$(echo -n $OPT | sed 's/--doc-id=\(.*\)/\1/') && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --crud=)" != "" ]] && CRUD=$(echo -n $OPT | sed 's/--crud=\(.*\)/\1/') && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --data=)" != "" ]] && DATA="$(echo -n ${OPT} | sed 's/--data=\"\(.*\)\"/\1/')" && illegal_arg=0
    [[ "$(echo -n ${OPT} | grep -e --hook=)" != "" ]] && HOOK="$(echo -n ${OPT} | sed 's/--hook=\(.*\)/\1/')" && illegal_arg=0
    if [ ! $illegal_arg -eq 0 ]
    then
      usage     #             # If we found an illegal argument, show usage and return 1.
      return 1
    fi
  done
  if [ -z $PIPE ] || [ -z $DOC_ID ] || [ -z $CRUD ] || [ -z $DATA ]
  then
    usage       #             # If we didn't receive all required arguments, show usage and return 1.
    return 1
  fi
  case $CRUD in
    create) ################################################################# CRUD Action: Create
      if [ ! -p $PIPE ] # no pipe
      then
        if [ "${PIPE}" == "--" ] # no pipe name
        then
          echo "ERROR: Must provide name of pipe." # error out
          return 1
        else # yes pipe name
          if [ "${DOC_ID}" == "--" ] # no doc id
          then
            echo "ERROR: Must provide name of document." # error out
            return 1
          else # yes doc id - (could be iterator)
            if [ "${DATA}" == "--" ] # no data
            then
              echo "ERROR: Must provide document data." # error out
              return 1
            else # yes data - (could be iterator)
              mkfifo -m 0600 $PIPE  # Create PIPE if it doesn't exist.
              ( \
                printf '%s\n' "BOF=${DOC_ID}" $DATA "EOF=${DOC_ID}" \
                'EOP' ' ' >> $PIPE & \
              ) # put doc containing data in pipe
            fi
          fi
        fi
      else # yes pipe
        if [ "${DOC_ID}" == "--" ] # no doc id
        then
          echo "ERROR: Must provide name of document." # error out
          return 1
        else # yes doc id
          read_lines_into_sync
          local duplicate_exists=1
          [ -z $(echo -n "${SYNC}" | grep -e $DOC_ID) ] && duplicate_exists=0
          if [ $duplicate_exists -eq 1 ] # yes doc found
          then
            echo "ERROR: document name already exists." # error out
            return 1
          else # no doc found
            if [ "${DATA}" == "--" ] # no data
            then
              echo "ERROR: Must provide document data." # error out
              return 1
            else # yes data
              ( \
                printf '%s\n' $SYNC "BOF=${DOC_ID}" $DATA "EOF=${DOC_ID}" \
                'EOP' ' ' >> $PIPE & \
              ) # append doc containing data to pipe
              SYNC= # Empty SYNC once action completed.
            fi
          fi
        fi
      fi
      ;;
    read) ################################################################### CRUD Action: Read
      if [ ! -p $PIPE ] # no pipe
      then
        echo "ERROR: Pipe ${PIPE} does not exist." # error out
        return 1
      else # yes pipe
        if [ "${DOC_ID}" == "--" ] # no doc id
        then
          if [ "${DATA}" == "--" ] # no data
          then
            read_lines_into_sync
            printf '%s\n' $SYNC # print entire pipe

            # TODO: conditionally restore based on HOOK

            ( \
              printf '%s\n' $SYNC \
              'EOP' ' ' >> $PIPE & \
            ) # restore contents of pipe
            SYNC= # empty sync when finished
          fi # yes data, do nothing
        else # yes doc id - (could be iterator)
          read_lines_into_sync
          if [ -z $(echo -n "${SYNC}" | grep -e $DOC_ID) ] # no doc found
          then
            ( \
              printf '%s\n' $SYNC \
              'EOP' ' ' >> $PIPE & \
            ) # restore contents of pipe before return 1
            SYNC= # empty sync when finished
            echo "ERROR: Document ID ${DOC_ID} not found." # error out
            return 1
          else # yes doc found
            local read_doc_contents="$(echo -n "$SYNC" | sed "s/\(BOF=${DOC_ID}\)\(.*\)\(EOF=${DOC_ID}\)/\1 \2 \3/")"
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
              local read_req_data_missing=1
              for read_var_name in $DATA # look for data
              do
                local read_req_data_match=$(echo -n "${read_doc_contents}" | sed "s/\(${read_var_name}\)=\(.*\),/\1=\2/")
                if [ ! -z read_req_data_match ]
                then
                  [ -z read_req_data ] && \
                  read_req_data="${read_req_data_match}," || \
                  read_req_data="${read_req_data} ${read_req_data_match},"
                  [ read_req_data_missing -eq 1 ] && read_req_data_missing=0
                fi
              done
              if [ read_req_data_missing -eq 1 ] # no data found
              then

                # TODO: conditionally restore based on HOOK

                ( \
                  printf '%s\n' $SYNC \
                  'EOP' ' ' >> $PIPE & \
                ) # restore contents of pipe before return 1
                SYNC= # empty sync when finished
                echo "ERROR: Requested data ${DATA} missing." # error out
                return 1
              else # yes data found
                printf '%s\n' $read_req_data # print only data
              fi
            fi
          fi
        fi
      fi
      ;;
    update) ################################################################# CRUD Action: Update
      if [ ! -p $PIPE ] # no pipe
      then
        echo "ERROR: Pipe ${PIPE} doesn't exist." # error out
        return 1
      else # yes pipe
        if [ "${DOC_ID}" == "--" ] # no doc id
        then
          echo "ERROR: Must provide name of document." # error out
          return 1
        else # yes doc id - (could be iterator)
          read_lines_into_sync
          if [ -z $(echo -n \"${SYNC}\" | grep -e ${DOC_ID}) ] # no doc found
          then

            # TODO: conditionally restore based on HOOK

            ( \
              printf '%s\n' $SYNC \
              'EOP' ' ' >> $PIPE & \
            ) # restore contents of pipe before return 1
            SYNC= # empty sync when finished
            echo "ERROR: Document ${DOC_ID} does not exist or was deleted." # error out
            return 1
          else # yes doc found
            local update_doc_contents="$(echo -n "$SYNC" | sed "s/\(BOF=${DOC_ID}\) \(.*\) \(EOF=${DOC_ID}\)/\1 \2 \3/")"
            if [ "${DATA}" == "--" ] # no data
            then

              # TODO: conditionally restore based on HOOK

              ( \
                printf '%s\n' $SYNC \
                'EOP' ' ' >> $PIPE & \
              ) # restore contents of pipe before return 1
              SYNC= # empty sync when finished
              echo "ERROR: Must provide document data." # error out
              return 1
            else # yes data - (could be iterator)
              local update_req_data=
              # local update_req_data_missing=1
              for update_var_val_pair in $DATA # look for data
              do
                local update_var_name=$(echo -n $update_var_val_pair | sed 's/\(.*\)=\(.*\),/\1/')
                local update_val_data="$(echo -n $update_var_val_pair | sed 's/\(.*\)=\(.*\),/\2/')"
                local update_req_data_match=$(echo -n "${update_doc_contents}" | sed "s/\(${update_var_name}\)=\(.*\),/\1=${update_val_data}/")
                if [ -z update_req_data_match ] # no data found
                then
                  [ -z update_req_data ] && \
                  update_req_data="${update_var_name}=${update_val_data}," || \
                  update_req_data="${update_req_data} ${update_var_name}=${update_val_data}," # append new data to doc
                else # yes data found
                  [ -z update_req_data ] && \
                  update_req_data="${update_req_data_match}," || \
                  update_req_data="${update_req_data} ${update_req_data_match}," # update only data
                fi
              done
              SYNC="$(echo -n ${SYNC} | sed "s/\(BOF=${DOC_ID}\) \(.*\) \(EOF=${DOC_ID}\)/\1 ${update_req_data} \3/")"

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
        return 1
      else # yes pipe
        if [ "${DOC_ID}" == "--" ] # no doc id
        then
          if [ "${DATA}" == "--" ] # no data
          then
            rm -f $PIPE # delete entire pipe
          fi # yes data, do nothing
        else # yes doc id - (could be iterator)
          read_lines_into_sync
          if [ -z $(echo -n "${SYNC}" | grep -e $DOC_ID) ] # no doc found
          then
            echo "ERROR: Document ID ${DOC_ID} not found." # error out
            return 1
          else # yes doc found
            local doc_contents="$(echo -n "$SYNC" | sed "s/\(BOF=${DOC_ID}\) \(.*\) \(EOF=${DOC_ID}\)/\1 \2 \3/")"
            if [ "${DATA}" == "--" ] # no data
            then
              SYNC="$(echo -n ${SYNC} | sed "s/${doc_contents}//")" # delete entire doc

              # TODO: conditionally restore based on HOOK

              ( \
                printf '%s\n' $SYNC \
                'EOP' ' ' >> $PIPE & \
              ) # restore remaining contents of doc
              SYNC= # empty sync when finished
            else # yes data - (could be iterator)
              local delete_req_data=
              local delete_req_data_missing=1
              for delete_var_name in $DATA # look for data
              do
                local delete_req_data_match=$(echo -n "${doc_contents}" | sed "s/\(${delete_var_name}\)=\(.*\),/\1=\2/")
                if [ ! -z delete_req_data_match ]
                then
                  [ -z delete_req_data ] && \
                  delete_req_data="${delete_req_data_match}," || \
                  delete_req_data="${delete_req_data} ${delete_req_data_match},"
                  [ delete_req_data_missing -eq 1 ] && delete_req_data_missing=0
                fi
              done
              if [ delete_req_data_missing -eq 1 ] # no data found
              then
                echo "ERROR: Requested data ${DATA} missing or already deleted." # error out
                return 1
              else # yes data found
                for delete_var_name in $DATA # delete only data
                do
                  SYNC="$(echo -n ${SYNC} | sed "s/BOF=${DOC_ID} \(.*\)${delete_var_name}=\(.*\),\(.*\) EOF=${DOC_ID}/BOF=${DOC_ID} \1 \3 EOF=${DOC_ID}/")"
                done

                # TODO: conditionally restore based on HOOK

                ( \
                  printf '%s\n' $SYNC \
                  'EOP' ' ' >> $PIPE & \
                ) # restore remaining contents of doc
                SYNC= # empty sync when finished
              fi
            fi
          fi
        fi
      fi
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
)