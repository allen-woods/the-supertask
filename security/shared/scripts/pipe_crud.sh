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

# * * * refactor * * * 
#
# pipe_crud -c -P|--pipe=name_of_pipe -D|--doc=id_of_doc -I|--items={"var1":"val1", "var2":"val2", "var3":"val3"}
#           -r
#           -u
#           -d
#
# pipe_crud -c -P=test_pipe -D=test_doc_01 -I={"var":"val"} --overwrite
# pipe_crud -r -P=test_pipe
# pipe_crud -r -P=test_pipe -D=test_doc_01
# pipe_crud -r -P=test_pipe -D=test_doc_01 -I={"var"}
# pipe_crud -u -P=test_pipe -D=test_doc_01 -I={"var":"new_val"}
# pipe_crud -u -P=test_pipe -D=test_doc_01 -I={"var":"new_val"} --replace_doc
# pipe_crud -d -P=test_pipe
# pipe_crud -d -P=test_pipe -D=test_doc_01
# pipe_crud -d -P=test_pipe -D=test_doc_01 -I={"var"}

pipe_crud() {
  local PIPE=
  local DOC=
  local ITEMS=
  local CRUD=
  local ADV_OPT=
  local SYNC=

  for arg in "${@}"; do # ..........................................START: Parse arguments. ###########################
    local pre=$(echo $arg | sed "s/\([-]\{1,2\}\).*/\1/g")
    local cmd=
    local str=
    [ ! -z "$(echo ${arg} | grep -o '=')" ] && cmd="$(echo ${arg} | cut -d '=' -f1)" || cmd="${arg}"
    [ ! -z "$(echo ${arg} | grep -o '=')" ] && str="$(echo ${arg} | cut -d '=' -f2)"
    case $cmd in
      -P|--pipe)
        PIPE="${str}"
        ;;
      -D|--doc)
        DOC="${str}"
        ;;
      -I|--items)
        ITEMS="$(echo -e ${str} | sed -e "s/[{}]//g; s/[\"\`\$\\]/\\\&/g")"
        ;;
      --overwrite-pipe)
        ADV_OPT=overwrite_pipe
        ;;
      --replace-all)
        ADV_OPT=replace_all
        ;;
      --delete-after)
        ADV_OPT=delete_after
        ;;
      --secure)
        ADV_OPT=secure
        ;;
      -c|--create)
        CRUD=create
        break
        ;;
      -r|--read)
        CRUD=read
        break
        ;;
      -u|--update)
        CRUD=update
        break
        ;;
      -d|--delete)
        CRUD=delete
        break
        ;;
      *)
        display_pipe_crud_usage
        return 1
        ;;
    esac
  done # ...........................................................END: Parse arguments. #############################

  if [ -z "${CRUD}" ]; then # ......................................User must provide a crud action.
    display_pipe_crud_usage
    return 1
  else
    if [ -z "${PIPE}" ]; then # ....................................User must provide a pipe name.
      display_pipe_crud_usage
      return 1
    else
      local MAP_FILE_DIR=/tmp
      local MAP_FILE=

      # This block of code determines if a map file already exists.
      # Based on its findings, it either generates the missing map file
      # or confirms the random filename where the map file is located.

      # No further action beyond generating or locating is permitted
      # at this point.

      if [ -z "$(ls -A ${MAP_FILE_DIR})" ]; then # .................No map file exists yet.
        MAP_FILE=$( \
          tr -cd a-f0-9 < /dev/urandom | \
          fold -w32 | \
          head -n1 \
        ) # ........................................................The map file is always randomly named.
        printf '%s\n' "$(echo 'PIPE_CRUD MAP FILE' | base64)" >> ${MAP_FILE_DIR}/${MAP_FILE}
      else # .......................................................File(s) present, the map file might already exist.
        for FILE in ${MAP_FILE_DIR}/*; do
          if [ "$(sed '1q;d' ${FILE} | base64 -d)" == "PIPE_CRUD MAP FILE" ]; then
            MAP_FILE=${FILE} # .....................................Map file identified.
            break
          fi
        done
      fi

      local PIPE_64="$(echo ${PIPE} | base64)"
      local PIPE_MAP_STRING="${PIPE_64}"
      local READ_FROM= # ...........................................Value is conditionally set later based
                                                                  # on presence of file descriptor in map
                                                                  # file.
      local WRITE_TO= # ............................................Value is conditionally set later based
                                                                  # on presence of file descriptor in map
                                                                  # file.
      local SYNC=
      #################################################################################################################
      if [ "${CRUD}" == "create" ]; then # .........................CREATE ############################################
      #################################################################################################################
        if [ -z "$(cat ${MAP_FILE_DIR}/${MAP_FILE} | grep -o ${PIPE_64})" ]; then
          # ........................................................FIFO has not been created yet.
          # NOTE: we only check for the advanced option "secure"
          #       once during the create crud action, as shown below.
          if [ "${ADV_OPT}" == "secure" ]; then
            local _TMP=$( \
              tr -cd a-f0-9 < /dev/urandom | \
              fold -w32 | \
              head -n1 \
            ) # ....................................................Random 16 byte hexadecimal temporary filename of FIFO.

            local PIPE_FD=
            local TEST_FD=6
            local LAST_FD=100

            while [ $TEST_FD -le $LAST_FD ]; do
              if [ ! -e /proc/$$/fd/$TEST_FD ]; then
                PIPE_FD=${TEST_FD} # ...............................Next available file descriptor.
                break
              fi
              TEST_FD=$(($TEST_FD + 1))
            done

            if [ -z "${PIPE_FD}" ]; then # .........................Handle edge case that no FD was found.
              echo "ERROR: File descriptor unavailable. Increase value of LAST_FD."
              return 1
            fi

            mkfifo $_TMP # .........................................Create temporary, randomly named FIFO.
            exec $PIPE_FD<> $_TMP # ................................Bind the I/O of the FIFO to PIPE_FD.
            unlink $_TMP # .........................................Delete temporary, randomly named FIFO.
            PIPE_MAP_STRING="${PIPE_MAP_STRING} ${PIPE_FD}" # ......Append a new line to our map file that
                                                            #       directs us to use PIPE_FD when looking
                                                            #       for PIPE.
            READ_FROM='<&'"${PIPE_FD}"
            WRITE_TO='>&'"${PIPE_FD}"
          else
            mkfifo $PIPE # .........................................Create regular, named FIFO.
            READ_FROM='< '"${PIPE}"
            WRITE_TO='>> '"${PIPE}"
          fi

          if [ ! -z "${DOC}" ]; then # .............................User is creating a document.
            if [ ! -z "${ITEMS}" ]; then # .........................Document contains items.
              SYNC="BOF=${DOC} ${ITEMS} EOF=${DOC}"
            else # .................................................Document contains no items.
              SYNC="BOF=${DOC} EOF=${DOC}"
            fi
          else
            SYNC= # ................................................User is only creating a pipe.
          fi
          
          eval "printf '%s\n' ${SYNC} 'EOP' ' ' ${WRITE_TO}" # ..............Write sync data to the pipe.

          printf '%s\n' "${PIPE_MAP_STRING}" >> ${MAP_FILE_DIR}/${MAP_FILE} # Populate map file regardless of data type.

          # NOTE: We use population within the map file to confirm
          #       existence of the pipe, whether it's in "named
          #       pipe" or "file descriptor" format.
        else # .....................................................FIFO has already been created.
          local PIPE_ADDRESS=

          while IFS= read -r LINE; do # ............................Locate mention of PIPE_64 on unknown line number.
            if [ ! -z "$(echo ${LINE} | grep -o ${PIPE_64})" ]; then
              PIPE_ADDRESS=$(echo $LINE | sed "s/${PIPE_64} \(.*\)/\1/g")
              break
            fi
          done < ${MAP_FILE_DIR}/${MAP_FILE}

          if [ -z "$(echo ${PIPE_ADDRESS} | sed 's/[0-9]\{0,\}//g')" ]; then
            # ......................................................File descriptors disappear completely in above line.
            READ_FROM='<&'"${PIPE_ADDRESS}"
            WRITE_TO='>&'"${PIPE_ADDRESS}"
          else
            # ......................................................Failure to find file descriptor returns PIPE_64 value.
            READ_FROM='< '"$(echo ${PIPE_ADDRESS} | base64 -d)"
            WRITE_TO='>> '"$(echo ${PIPE_ADDRESS} | base64 -d)"
          fi

          if [ -z "${DOC}" ]; then # ...............................When the user is not creating a document,
            if [ "${ADV_OPT}" != "overwrite_pipe" ]; then # ........And they are not overwriting the pipe,
              echo "ERROR: Pipe Already Exists." # .................Error out.
              return 1
            else
              SYNC= # ..............................................But if they overwriting the pipe, send in empty data.
            fi
          else # ...................................................In the event the user is creating a document,
                                                                  # qrab the contents of the pipe first so we can check
                                                                  # for duplicates.
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.

            eval '
            while IFS= read -r CREATE_DOC_DATA; do
              if [ '"${CREATE_DOC_DATA}"' == "EOP" ]; then
                break
              else
                if [ -z '"${SYNC}"' ]; then
                  SYNC='"${CREATE_DOC_DATA}"'
                else
                  SYNC='"${SYNC} ${CREATE_DOC_DATA}"'
                fi
              fi
            done '"${READ_FROM}"

            if [ "${ADV_OPT}" == "overwrite_pipe" ]; then # ........When overwrite of pipe is desired,
              if [ ! -z "${ITEMS}" ]; then # .......................Do not prepend old value of SYNC at the front.
                SYNC="BOF=${DOC} ${ITEMS} EOF=${DOC}"
              else
                SYNC="BOF=${DOC} EOF=${DOC}"
              fi
            else
              if [ ! -z "$(echo ${SYNC} | grep -o ${DOC})"]; then # If we find a dupliate of the document,
                echo "ERROR: Document \"${DOC}\" Already Exists." # Error out.
                return 1
              else # ...............................................Otherwise prepend old value of SYNC before data.
                if [ ! -z "${ITEMS}" ]; then
                  SYNC="${SYNC} BOF=${DOC} ${ITEMS} EOF=${DOC}"
                else
                  SYNC="${SYNC} BOF=${DOC} EOF=${DOC}"
                fi
              fi
            fi

            eval "printf '%s\n' ${SYNC} 'EOP' ' ' ${WRITE_TO}" # ..........In any case, print the data back into the pipe.
            SYNC= # Reset value of SYNC.
          fi
        fi
      #################################################################################################################
      elif [ "${CRUD}" == "read" ]; then # .........................READ ##############################################
      #################################################################################################################
        if [ -z "$(cat ${MAP_FILE_DIR}/${MAP_FILE} | grep -o ${PIPE_64})" ]; then
          # ........................................................FIFO doesn't exist for unknown reason.
          echo "ERROR: The Pipe Does Not Exist or Was Deleted."
          return 1
        else # .....................................................FIFO exists.
          local PIPE_ADDRESS=
          
          while IFS= read -r LINE; do # ............................Locate mention of PIPE_64 on unknown line number.
            if [ ! -z "$(echo ${LINE} | grep -o ${PIPE_64})" ]; then
              PIPE_ADDRESS=$(echo $LINE | sed "s/${PIPE_64} \(.*\)/1/g")
              break
            fi
          done < ${MAP_FILE_DIR}/${MAP_FILE}

          if [ -z "$(echo ${PIPE_ADDRESS} | sed 's/[0-9]\{0,\}//g')" ]; then
            # ......................................................File descriptor.
            READ_FROM='<&'"${PIPE_ADDRESS}"
            WRITE_TO='>&'"${PIPE_ADDRESS}"
          else
            # ......................................................Named pipe.
            READ_FROM='< '"$(echo ${PIPE_ADDRESS} | base64 -d)"
            WRITE_TO='>> '"$(echo ${PIPE_ADDRESS} | base64 -d)"
          fi

          local read_bof_doc_found=0
          local read_eof_doc_found=0
          local read_item_found=0
          local read_item_val=
          local read_output=

          if [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then # ........We are reading the entire document, no individual items.
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            while IFS= read -r READ_DOC_DATA; do
              if [ '"${READ_DOC_DATA}"' == "EOP" ]; then
                break
              else
                if [ ! -z '"$(echo ${READ_DOC_DATA} | grep -o BOF=${DOC})"' ]; then
                  read_bof_doc_found=1
                elif [ ! -z '"$(echo ${READ_DOC_DATA} | grep -o EOF=${DOC})"' ]; then
                  read_eof_doc_found=1
                elif [ '"$read_bof_doc_found"' -eq 1 ] && [ '"$read_eof_doc_found"' -eq 1 ]; then
                  read_bof_doc_found=0
                  read_eof_doc_found=0
                fi
                if [ '"$read_bof_doc_found"' -gt 0 ]; then
                  read_item_val='"$(echo ${READ_DOC_DATA} | sed -e "s/.*\\\"\(.*\)\\\":\\\"\(.*\)\\\".*/\2/g")"'
                  if [ -z '"${read_output}"' ]; then
                    read_output='"${read_item_val}"'
                  else
                    read_output='"${read_output} ${read_item_val}"'
                  fi
                  if [ '"${ADV_OPT}"' != "delete_after" ]; then
                    if [ -z '"${SYNC}"' ]; then
                      SYNC='"${READ_DOC_DATA}"'
                    else
                      SYNC='"${SYNC} ${READ_DOC_DATA}"'
                    fi
                  fi
                else
                  if [ -z '"${SYNC}"' ]; then
                    SYNC='"${READ_DOC_DATA}"'
                  else
                    SYNC='"${SYNC} ${READ_DOC_DATA}"'
                  fi
                fi
              fi
            done '"${READ_FROM}"
            echo "${read_output}" # ................................Send data to stdout in an easily parsed format.
          elif [ -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then # ......We are reading common items across documents, not any one document.
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            while IFS= read -r READ_DOC_DATA; do
              if [ '"${READ_DOC_DATA}"' == "EOP" ]; then
                break
              else
                read_item_found=0
                for READ_ITEM in '"${ITEMS}"'; do
                  if [ ! -z '"$(echo ${READ_DOC_DATA} | grep -o ${READ_ITEM})"' ]; then
                    read_item_found=1
                    break
                  fi
                done
                if [ '"$read_item_found"' -gt 0 ]; then
                  read_item_val='"$(echo ${READ_DOC_DATA} | sed -e "s/.*\\\"\(.*\)\\\":\\\"\(.*\)\\\".*/\2/g")"'
                  if [ -z '"${read_output}"' ]; then
                    read_output='"${read_item_val}"'
                  else
                    read_output='"${read_output} ${read_item_val}"'
                  fi
                  if [ '"${ADV_OPT}"' != "delete_after" ]; then
                    if [ -z '"${SYNC}"' ]; then
                      SYNC='"${READ_DOC_DATA}"'
                    else
                      SYNC='"${SYNC} ${READ_DOC_DATA}"'
                    fi
                  fi
                else
                  if [ -z '"${SYNC}"' ]; then
                    SYNC='"${READ_DOC_DATA}"'
                  else
                    SYNC='"${SYNC} ${READ_DOC_DATA}"'
                  fi
                fi
              fi
            done '"${READ_FROM}"
            echo "${read_output}"
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then # ....We are reading specific items from a specific document.
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            while IFS= read -r READ_DOC_DATA; do
              if [ '"${READ_DOC_DATA}"' == "EOP" ]; then
                break
              else
                if [ ! -z '"$(echo ${READ_DOC_DATA} | grep -o BOF=${DOC})"' ]; then
                  read_bof_doc_found=1
                elif [ ! -z '"$(echo ${READ_DOC_DATA} | grep -o EOF=${DOC})"' ]; then
                  read_eof_doc_found=1
                elif [ '"$read_bof_doc_found"' -eq 1 ] && [ '"$read_eof_doc_found"' -eq 1 ]; then
                  read_bof_doc_found=0
                  read_eof_doc_found=0
                fi
                if [ '"$read_bof_doc_found"' -eq 1 ]; then
                  read_item_found=0
                  for READ_ITEM in '"${ITEMS}"'; do
                    if [ ! -z '"$(echo ${READ_DOC_DATA} | grep -o ${READ_ITEM})"' ]; then
                      read_item_found=1
                      break
                    fi
                  done
                fi
                if [ '"$read_bof_doc_found"' -eq 1 ] && [ '"$read_item_found"' -eq 1 ]; then
                  read_item_val='"$(echo ${READ_DOC_DATA} | sed -e "s/.*\\\"\(.*\)\\\":\\\"\(.*\)\\\".*/\2/g")"'
                  if [ -z '"${read_output}"' ]; then
                    read_output='"${read_item_val}"'
                  else
                    read_output='"${read_output} ${read_item_val}"'
                  fi
                  if [ '"${ADV_OPT}"' != "delete_after" ]; then
                    if [ -z '"${SYNC}"' ]; then
                      SYNC='"${READ_DOC_DATA}"'
                    else
                      SYNC='"${SYNC} ${READ_DOC_DATA}"'
                    fi
                  fi
                else
                  if [ -z '"${SYNC}"' ]; then
                    SYNC='"${READ_DOC_DATA}"'
                  else
                    SYNC='"${SYNC} ${READ_DOC_DATA}"'
                  fi
                fi
              fi
            done '"${READ_FROM}"
            echo "${read_output}"
          fi

          eval "printf '%s\n' ${SYNC} 'EOP' ' ' ${WRITE_TO}"
        fi
      #################################################################################################################
      elif [ "${CRUD}" == "update" ]; then # .......................UPDATE ############################################
      #################################################################################################################
        if [ -z "$(cat ${MAP_FILE_DIR}/${MAP_FILE} | grep -o ${PIPE_64})" ]; then
          #.........................................................FIFO doesn't exist for unknown reason.
          echo "ERROR: The Pipe Does Not Exist or Was Deleted."
          return 1
        else # .....................................................FIFO exists.
          local PIPE_ADDRESS=

          while IFS read -r LINE; do # .............................Locate mention of PIPE_64 on unknown line number.
            if [ ! -z "$(echo ${LINE} | grep -o ${PIPE_64})" ]; then
              PIPE_ADDRESS=$(echo $LINE | sed "s/${PIPE_64} \(.*\)/1/g")
              break
            fi
          done < ${MAP_FILE_DIR}/${MAP_FILE}

          if [ -z "$(echo ${PIPE_ADDRESS} | sed 's/[0-9]\{0,\}//g')" ]; then
            # ......................................................File descriptor.
            READ_FROM='<&'"${PIPE_ADDRESS}"
            WRITE_TO='>&'"${PIPE_ADDRESS}"

            if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
              if [ "${ADV_OPT}" == "replace_all" ]; then # .........Replace all empties everything when scoped to the pipe.
                eval '
                while IFS read -r WIPE_DATA; do
                  if [ '"${WIPE_DATA}"' == "EOP" ]; then
                    break
                  else
                    echo '"${WIPE_DATA}"' >/dev/null
                  fi
                done '"${READ_FROM}"

                eval "printf '%s\n' 'EOP' ' ' ${WRITE_TO}" # .......Prevent blocking of subsequent reads or writes.
              fi
              return 0 # ...........................................Go no further, pipe was emptied or nothing to update.
            fi
          else
            # ......................................................Named pipe.
            READ_FROM='< '"$(echo ${PIPE_ADDRESS} | base64 -d)"
            WRITE_TO='>> '"$(echo ${PIPE_ADDRESS} | base64 -d)"

            if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
              if [ "${ADV_OPT}" == "replace_all" ]; then # .........Replace all empties everything when scoped to the pipe.
                eval '
                while IFS read -r WIPE_DATA; do
                  if [ '"${WIPE_DATA}"' == "EOP" ]; then
                    break
                  else
                    echo '"${WIPE_DATA}"' >/dev/null
                  fi
                done '"${READ_FROM}"

                eval "printf '%s\n' 'EOP' ' ' ${WRITE_TO}" # .......Prevent blocking of subsequent reads or writes.
              fi
              return 0 # ...........................................Go no further, pipe was emptied or nothing to update.
            fi
          fi

          local UPDATE_LINE_NUM=1
          local update_bof_doc_found=0
          local update_bof_line_num=
          local update_eof_doc_found=0
          local update eof_line_num=
          local update_item_found=0
          local update_item_val=

          if [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            while IFS read -r UPDATE_DOC_DATA; do
              if [ '"${UPDATE_DOC_DATA}"' == "EOP" ]; then
                break
              else
                if [ ! -z '"$(echo ${UPDATE_DOC_DATA} | grep -o BOF=${DOC})"' ]; then
                  update_bof_doc_found=1
                  update_bof_line_num='"${UPDATE_LINE_NUM}"'
                elif [ ! -z '"$(echo ${UPDATE_DOC_DATA} | grep -o EOF=${DOC})"' ]; then
                  update_eof_doc_found=1
                  update_eof_line_num='"${UPDATE_LINE_NUM}"'
                elif [ '"$update_bof_doc_found"' -eq 1 ] && [ '"$update_eof_doc_found"' -eq 1 ]; then
                  update_bof_doc_found=0
                  update_bof_line_num=
                  update_eof_doc_found=0
                  update_eof_line_num=
                fi
                if [ '"${ADV_OPT}"' == "replace_all" ]; then
                  # if we are on BOF or EOF line, allow it to go to sync.
                  # Otherwise, allow everything else to go to sync.
                  if [ '"$update_bof_line_num"' == '"$UPDATE_LINE_NUM"' ] || [ '"$update_eof_line_num"' == '"$UPDATE_LINE_NUM"' ]; then
                    if [ -z '"${SYNC}"' ]; then
                      SYNC='"${UPDATE_DOC_DATA}"'
                    else
                      SYNC='"${SYNC} ${UPDATE_DOC_DATA}"'
                    fi
                  elif [ '"$update_bof_doc_found"' -eq 0 ] && [ '"$update_eof_doc_found"' -eq 0 ]; then
                    if [ -z '"${SYNC}"' ]; then
                      SYNC='"${UPDATE_DOC_DATA}"'
                    else
                      SYNC='"${SYNC} ${UPDATE_DOC_DATA}"'
                    fi
                  fi
                else
                  if [ -z '"${SYNC}"' ]; then
                    SYNC='"${UPDATE_DOC_DATA}"'
                  else
                    SYNC='"${SYNC} ${UPDATE_DOC_DATA}"'
                  fi
                fi
              fi
              UPDATE_LINE_NUM='"$((${UPDATE_LINE_NUM} + 1))"'
            done '"${READ_FROM}"
          elif [ -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            done '"${READ_FROM}"
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            done '"${READ_FROM}"
          fi

          eval "printf '%s\n' ${SYNC} 'EOP' ' ' ${WRITE_TO}"
        fi
      #################################################################################################################
      elif [ "${CRUD}" == "delete" ]; then # .......................DELETE ############################################
      #################################################################################################################
        if [ -z "$(cat ${MAP_FILE_DIR}/${MAP_FILE} | grep -o ${PIPE_64})" ]; then
          # ........................................................FIFO doesn't exist for unknown reason.
          echo "ERROR: The Pipe Does Not Exist or Was Deleted."
          return 1
        else # .....................................................FIFO exists.
          local PIPE_ADDRESS=
          local MAP_LINE_NUM=1

          while IFS= read -r LINE; do # ............................Locate mention of PIPE_64 on unknown line number.
            if [ ! -z "$(echo ${LINE} | grep -o ${PIPE_64})" ]; then
              PIPE_ADDRESS=$(echo $LINE | sed "s/${PIPE_64} \(.*\)/\1/g")
              break
            fi
            MAP_LINE_NUM=$((MAP_LINE_NUM + 1)) # ...................Increment line number to allow for deletion in map file.
          done < ${MAP_FILE_DIR}/${MAP_FILE}

          if [ -z "$(echo ${PIPE_ADDRESS} | sed 's/[0-9]\{0,\}//g')" ]; then
            # ......................................................File descriptor.
            READ_FROM='<&'"${PIPE_ADDRESS}"
            WRITE_TO='>&'"${PIPE_ADDRESS}"

            if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then # ........Delete file descriptor and its mention in map file.
              eval "${WRITE_TO}-"
              sed -i "${MAP_LINE_NUM}d" ${MAP_FILE_DIR}/${MAP_FILE}
              return 0 # ...........................................Go no further, entire pipe deleted.
            fi
          else
            # ......................................................Named pipe.
            READ_FROM='< '"$(echo ${PIPE_ADDRESS} | base64 -d)"
            WRITE_TO='>> '"$(echo ${PIPE_ADDRESS} | base64 -d)"

            if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then # ........Delete named pipe and its mention in map file.
              rm -f $PIPE_ADDRESS
              sed -i "${MAP_LINE_NUM}d" ${MAP_FILE_DIR}/${MAP_FILE}
              return 0 # ...........................................Go no further, entire pipe deleted.
            fi
          fi

          local del_bof_doc_found=0
          local del_eof_doc_found=0
          local del_item_found=0

          if [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then # ........We are deleting an entire document, no items.
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            while IFS= read -r DELETE_DOC_DATA; do
              if [ '"${DELETE_DOC_DATA}"' == "EOP" ]; then
                break
              else
                if [ ! -z '"$(echo ${DELETE_DOC_DATA} | grep -o BOF=${DOC})"' ]; then
                  del_bof_doc_found=1
                elif [ ! -z '"$(echo ${DELETE_DOC_DATA} | grep -o EOF=${DOC})"' ]; then
                  del_eof_doc_found=1
                elif [ '"$del_bof_doc_found"' -eq 1 ] && [ '"$del_eof_doc_found"' -eq 1 ]; then
                  del_bof_doc_found=0
                  del_eof_doc_found=0
                fi
                if [ '"$del_bof_doc_found"' -eq 0 ]; then
                  if [ -z '"${SYNC}"' ]; then
                    SYNC='"${DELETE_DOC_DATA}"'
                  else
                    SYNC='"${SYNC} ${DELETE_DOC_DATA}"'
                  fi
                fi
              fi
            done '"${READ_FROM}"
          elif [ -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then # ......We are deleting common items across documents, not any one document.
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            while IFS= read -r DELETE_DOC_DATA; do
              if [ '"${DELETE_DOC_DATA}"' == "EOP" ]; then
                break
              else
                del_item_found=0
                for DELETE_ITEM in '"${ITEMS}"'; do
                  if [ ! -z '"$(echo ${DELETE_DOC_DATA} | grep -o ${DELETE_ITEM})"' ]; then
                    del_item_found=1
                    break
                  fi
                done
                if [ '"$del_item_found"' -eq 0 ]; then
                  if [ -z '"${SYNC}"' ]; then
                    SYNC='"${DELETE_DOC_DATA}"'
                  else
                    SYNC='"${SYNC} ${DELETE_DOC_DATA}"'
                  fi
                fi
              fi
            done '"${READ_FROM}"
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then # ....We are deleting specific items within a specific document.
            # CAUTION:  Use of `eval` is dangerous and considered
                      # bad practice. `eval` is used here solely to
                      # prevent code duplication by way of the
                      # `READ_FROM` and `WRITE_TO` variables.
                      #
                      # This utility is only used briefly during
                      # a single intermediate build stage.
            eval '
            while IFS= read -r DELETE_DOC_DATA; do
              if [ '"${DELETE_DOC_DATA}"' == "EOP" ]; then
                break
              else
                if [ ! -z '"$(echo ${DELETE_DOC_DATA} | grep -o BOF=${DOC})"' ]; then
                  del_bof_doc_found=1
                elif [ ! -z '"$(echo ${DELETE_DOC_DATA} | grep -o EOF=${DOC})"' ]; then
                  del_eof_doc_found=1
                elif [ '"$del_bof_doc_found"' -eq 1 ] && [ '"$del_eof_doc_found"' -eq 1 ]; then
                  del_bof_doc_found=0
                  del_eof_doc_found=0
                fi
                if [ '"$del_bof_doc_found"' -eq 1 ]; then
                  del_item_found=0
                  for DELETE_ITEM in '"${ITEMS}"'; do
                    if [ ! -z '"$(echo ${DELETE_DOC_DATA} | grep -o ${DELETE_ITEM})"' ]; then
                      del_item_found=1
                      break
                    fi
                  done
                fi
                if [ '"$del_bof_doc_found"' -eq 0 ] || [ '"$del_item_found"' -eq 0 ]; then
                  if [ -z '"${SYNC}"' ]; then
                    SYNC='"${DELETE_DOC_DATA}"'
                  else
                    SYNC='"${SYNC} ${DELETE_DOC_DATA}"'
                  fi
                fi
              fi
            done '"${READ_FROM}"
          fi
          eval "printf '%s\n' ${SYNC} 'EOP' ' ' ${WRITE_TO}"
        fi
      fi
    fi
  fi
}