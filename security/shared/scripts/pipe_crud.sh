#!/bin/sh

# TODO: rewrite usage to reflect changes in refactor.

display_pipe_crud_usage() {
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
  # ............................................................... Parse arguments. ##################################
  for arg in "${@}"; do
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
      # ........................................................... Only available when creating new pipe.
      --secure)
        ADV_OPT=secure
        ;;
      # ........................................................... Only available when creating new records in existing pipe.
      --overwrite-pipe)
        ADV_OPT=overwrite_pipe
        ;;
      # ........................................................... Only available when reading from existing, populated pipe.
      --delete-after)
        ADV_OPT=delete_after
        ;;
      # ........................................................... Only available when updating existing, populated pipe.
      --replace-all)
        ADV_OPT=replace_all
        ;;
      # ........................................................... Only available when deleting from existing, populated pipe.
      --except-for)
        ADV_OPT=except_for
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
  done
  # ............................................................... User must provide a crud action.
  if [ -z "${CRUD}" ]; then
    display_pipe_crud_usage
    return 1
  else
    # ............................................................. User must provide a pipe name to reference.
    if [ -z "${PIPE}" ]; then
      display_pipe_crud_usage
      return 1
    else
      local MAP_FILE_DIR=/tmp
      local MAP_FILE=
      # ........................................................... Map file directory doesn't exist yet.
      if [ ! -d $MAP_FILE_DIR ]; then
        mkdir -p $MAP_FILE_DIR
      fi
      # ........................................................... Map file does not exist yet.
      if [ -z "$(ls -A ${MAP_FILE_DIR})" ]; then
        # ......................................................... Always generate a random name for the map file.
        MAP_FILE=$( \
          tr -cd a-f0-9 < /dev/urandom | \
          fold -w32 | \
          head -n1 \
        )
        # ......................................................... Place encoded identifying information into the map file.
        printf '%s\n' "$(echo 'PIPE_CRUD MAP FILE' | base64)" >> "${MAP_FILE_DIR}/${MAP_FILE}"
      # ........................................................... File(s) are present in MAP_FILE_DIR, the map file might already exist.
      else
        for FILE in ${MAP_FILE_DIR}/*; do
          if [ "$(sed '1q;d' ${FILE} | base64 -d)" == "PIPE_CRUD MAP FILE" ]; then
            # ..................................................... Map file identified.
            MAP_FILE=${FILE}
            break
          fi
        done
      fi

      local PIPE_64="$(echo ${PIPE} | base64)"
      local PIPE_MAP_STRING="${PIPE_64}"
      local IS_FD=0
      local SYNC=
      # ........................................................... FIFO has not been created yet.
      if [ -z "$(cat ${MAP_FILE_DIR}/${MAP_FILE} | grep -o ${PIPE_64})" ]; then
        #################################################################################################################
        if [ "${CRUD}" == "create" ]; then # ...................... CREATE - part 1 #####################################
        #################################################################################################################
          # NOTE: we only check for the advanced option "secure"
          #       once during the create crud action, as shown below.
          if [ "${ADV_OPT}" == "secure" ]; then
            local _TMP=$( \
              tr -cd a-f0-9 < /dev/urandom | \
              fold -w32 | \
              head -n1 \
            ) # ................................................... Random 16 byte hexadecimal temporary filename of FIFO.
            # ..................................................... Delare variables used to locate available file descriptors.
            local PIPE_FD=
            local TEST_FD=6
            local LAST_FD=100
            # ..................................................... Iterate over file descriptors.
            while [ $TEST_FD -le $LAST_FD ]; do
              if [ ! -e /proc/$$/fd/$TEST_FD ]; then
                PIPE_FD=${TEST_FD} # .............................. Next available file descriptor.
                break
              fi
              TEST_FD=$(($TEST_FD + 1))
            done
            # ..................................................... Handle edge case that no FD was found.
            if [ -z "${PIPE_FD}" ]; then
              echo "ERROR: File descriptor unavailable. Increase value of LAST_FD."
              return 1
            fi
            # ..................................................... Build the secure pipe as follows:
            mkfifo $_TMP
            exec $PIPE_FD<> $_TMP
            unlink $_TMP
            PIPE_MAP_STRING="${PIPE_MAP_STRING} ${PIPE_FD}" # ..... Append a new line to our map file that
                                                                  # directs us to use PIPE_FD when looking
                                                                  # for PIPE.
            if [ $IS_FD -eq 0 ]; then # ........................... Let the rest of the sccript know this
              IS_FD=1                                             # is a secure pipe.
            fi
          else
            mkfifo $PIPE # ........................................ Create regular, named FIFO.
          fi
          # ....................................................... User is creating a document.
          if [ ! -z "${DOC}" ]; then
            if [ ! -z "${ITEMS}" ]; then # ........................ Document contains items.
              SYNC="BOF=${DOC} ${ITEMS} EOF=${DOC}"
            else # ................................................ Document contains no items.
              SYNC="BOF=${DOC} EOF=${DOC}"
            fi
          # ....................................................... User is only creating a pipe.
          else
            SYNC=
          fi
          # ....................................................... Place initial data into the pipe to prevent blocking of subsequent reads and writes.
          if [ $IS_FD -eq 1 ]; then
            printf '%s\n' $SYNC 'EOP' ' ' >&"${PIPE_FD}" &
          else
            printf '%s\n' $SYNC 'EOP' ' ' >> "${PIPE}"
          fi
          ##########################################################
          # NOTE:                                                  #
          #       We use population within the map file to confirm #
          #       existence of the pipe, whether it's in "named    #
          #       pipe" or "file descriptor" format.               #
          #                                                        #
          ##########################################################
          # ........................................................Populate map file to confirm the pipe was created.
          printf '%s\n' "${PIPE_MAP_STRING}" >> "${MAP_FILE_DIR}/${MAP_FILE}"
        fi
      #
      else # .......................................................FIFO has already been created.
      #
        local PIPE_ADDRESS= # ......................................Resolves to named pipe or file descriptor where crud pipe is located.
        local PIPE_LINE_NUM=1 # ....................................Track the line number where PIPE_64 appears to delete it in the "delete" crud action body.
        # ..........................................................Locate mention of PIPE_64 on unknown line number.
        while IFS= read -r LINE; do
          if [ ! -z "$(echo ${LINE} | grep -o ${PIPE_64})" ]; then
            PIPE_ADDRESS=$(echo $LINE | sed "s/${PIPE_64} \(.*\)/\1/g")
            break
          fi
          PIPE_LINE_NUM=$(($PIPE_LINE_NUM + 1))
        done < "${MAP_FILE_DIR}/${MAP_FILE}"
        # ..........................................................If erasing digits completely erases PIPE_ADDRESS, the pipe is in a file descriptor.
        if [ -z "$(echo ${PIPE_ADDRESS} | sed 's/[0-9]\{0,\}//g')" ]; then
          if [ $IS_FD -eq 0 ]; then
            IS_FD=1
          fi
        fi
        # ..........................................................Pull all DATA out of the pipe once, before any data mutation.
        if [ $IS_FD -eq 1 ]; then
          while IFS= read -r DATA; do
            if [ "${DATA}" == "EOP" ]; then
              break
            else
              if [ -z "${SYNC}" ]; then
                SYNC="${DATA}"
              else
                SYNC="${SYNC} ${DATA}"
              fi
            fi
          done <&"${PIPE_ADDRESS}"
        else
          while IFS= read -r DATA; do
            if [ "${DATA}" == "EOP" ]; then
              break
            else
              if [ -z "${SYNC}" ]; then
                SYNC="${DATA}"
              else
                SYNC="${SYNC} ${DATA}"
              fi
            fi
          done < "$(echo ${PIPE_ADDRESS} | base64 -d)"
        fi
        #################################################################################################################
        if [ "${CRUD}" == "create" ]; then # .......................CREATE - part 2 #####################################
        #################################################################################################################
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ "${ADV_OPT}" == "overwrite_pipe" ]; then
              SYNC=
            else
              echo "ERROR: Pipe already exists."
              return 1
            fi
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ "${ADV_OPT}" == "overwrite_pipe" ]; then
              SYNC="BOF=${DOC} EOF=${DOC}"
            else
              if [ ! -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
                echo "ERROR: Document \"${DOC}\" already exists."
                return 1
              else
                if [ -z "${SYNC}" ]; then
                  SYNC="BOF=${DOC} EOF=${DOC}"
                else
                  SYNC="${SYNC} BOF=${DOC} EOF=${DOC}"
                fi
              fi
            fi
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            if [ "${ADV_OPT}" == "overwrite_pipe" ]; then
              SYNC="BOF=${DOC} ${ITEMS} EOF=${DOC}"
            else
              local CREATE_ITEM_NAMES=
              for CREATE_ITEM in $ITEMS; do
                local PARSED_ITEM_NAME=$( \
                  echo ${CREATE_ITEM} | \
                  sed 's/\(\\\"\)\(.*\)\(\\\"\)\(:\\\".*\\\"\).*/\2/g' \
                )
                if [ ! -z "$(echo ${CREATE_ITEM_NAMES} | grep -o ${PARSED_ITEM_NAME})" ]; then
                  echo "ERROR: Item name \"${PARSED_ITEM_NAME}\" must be unique."
                  return 1
                else
                  if [ -z "${CREATE_ITEM_NAMES}" ]; then
                    CREATE_ITEM_NAMES="${PARSED_ITEM_NAME}"
                  else
                    CREATE_ITEM_NAMES="${CREATE_ITEM_NAMES} ${PARSED_ITEM_NAME}"
                  fi
                fi
              done
              if [ -z "${SYNC}" ]; then
                SYNC="BOF=${DOC} ${ITEMS} EOF=${DOC}"
              else
                SYNC="${SYNC} BOF=${DOC} ${ITEMS} EOF=${DOC}"
              fi
            fi
          fi
        fi
        #################################################################################################################
        elif [ "${CRUD}" == "read" ]; then # .......................READ ################################################
        #################################################################################################################
          local READ_OUTPUT=
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            printf '%s\n' $SYNC
            if [ "${ADV_OPT}" == "delete_after" ]; then
              SYNC=
            fi
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
              echo "ERROR: Document \"${DOC}\" does not exist or was deleted."
              return 1
            else
              printf '%s\n' $(echo $SYNC | grep -o BOF=${DOC}.*EOF=${DOC})
              if [ "${ADV_OPT}" == "delete_after" ]; then
                SYNC=$(echo $SYNC | sed 's/BOF='"${DOC}"'.*EOF='"${DOC}"'/ /g; s/  / /g')
              fi
            fi
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            for READ_ITEM in $ITEMS; do
              if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*${READ_ITEM}.*EOF=${DOC} | grep -o ${READ_ITEM})" ]; then
                echo "ERROR: Item \"${READ_ITEM}\" does not exist or was deleted."
                return 1
              else
                local READ_MATCH=$( \
                  echo ${SYNC} | \
                  sed 's/.*BOF='"${DOC}"'.*\('"${READ_ITEM}"'\):\\\"\(.*\)\\\".*EOF='"${DOC}"'.*/\2/g' \
                )
                if [ -z "${READ_OUTPUT}" ]; then
                  READ_OUTPUT="${READ_MATCH}"
                else
                  READ_OUTPUT="${READ_OUTPUT} ${READ_MATCH}"
                fi
                if [ "${ADV_OPT}" == "delete_after" ]
                  SYNC="$( \
                    echo ${SYNC} | \
                    sed 's/\(.*BOF='"${DOC}"'.*\)\('"${READ_ITEM}"'":\\\".*\\\"\)\(.*EOF='"${DOC}"'.*\)/\1 \3/g; s/  / /g' \
                  )"
                fi
              fi
            done
            echo $READ_OUTPUT
          fi
        #################################################################################################################
        elif [ "${CRUD}" == "update" ]; then # .....................UPDATE ##############################################
        #################################################################################################################
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ "${ADV_OPT}" == "replace_all" ]; then
              SYNC=
            else
              echo "ERROR: Nothing to update."
              display_pipe_crud_usage
              return 1
            fi
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
              echo "ERROR: Document \"${DOC}\" does not exist or was deleted."
              return 1
            else
              if [ "${ADV_OPT}" == "replace_all" ]; then
                SYNC="$(echo ${SYNC} | sed 's/\(.*BOF='"${DOC}"'\)\(.*\)\(EOF='"${DOC}"'.*\)/\1 \3/g; s/  / /g')"
              else
                echo "ERROR: Nothing to update."
                display_pipe_crud_usage
                return 1
              fi
            fi
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            local UPDATE_NEW_ITEMS=
            for UPDATE_ITEM in $ITEMS; do
              local PARSED_ITEM_NAME=$( \
                echo ${UPDATE_ITEM} | \
                sed 's/\(\\\"\)\(.*\)\(\\\"\)\(:\\\".*\\\"\).*/\2/g' \
              )
              if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*${PARSED_ITEM_NAME}.*EOF=${DOC} | grep -o ${PARSED_ITEM_NAME})" ]; then
                SYNC="$( \
                  echo ${SYNC} | \
                  sed 's/\(.*BOF='"${DOC}"'\)\(.*\)\(EOF='"${DOC}"'.*\)/\1 \2 '"${UPDATE_ITEM}"' \3/g; s/  / /g'
                )"
              else
                if [ "${ADV_OPT}" == "replace_all" ]; then
                  if [ -z "${UPDATE_NEW_ITEMS}" ]; then
                    UPDATE_NEW_ITEMS="${UPDATE_ITEM}"
                  else
                    UPDATE_NEW_ITEMS="${UPDATE_NEW_ITEMS} ${UPDATE_ITEM}"
                  fi
                else
                  SYNC="$( \
                    echo ${SYNC} | \
                    sed 's/\(.*BOF='"${DOC}"'.*\)\(\\\"'"${PARSED_ITEM_NAME}"'\\\":\\\".*\\\"\)\(.*EOF='"${DOC}"'.*\)/\1 '"${UPDATE_ITEM}"' \3/g; s/  / /g' \
                  )"
                fi
              fi
            done
            if [ "${ADV_OPT}" == "replace_all" ] && [ ! -z "${UPDATE_NEW_ITEMS}" ]; then
              SYNC="$( \
                echo ${SYNC} | \
                sed 's/\(.*BOF='"${DOC}"'\).*\(EOF='"${DOC}"'.*\)/\1 '"${UPDATE_NEW_ITEMS}"' \2/g; s/  / /g'
              )"
            fi
          fi
        #################################################################################################################
        elif [ "${CRUD}" == "delete" ]; then # .....................DELETE ##############################################
        #################################################################################################################
          local KEEP_ITEMS=
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ $IS_FD -eq 1 ]; then
              >&"${PIPE_ADDRESS}-"
            else
              rm -f "$(echo ${PIPE_ADDRESS} | base64 -d)"
            fi
            sed -i "${PIPE_LINE_NUM}d" "${MAP_FILE_DIR}/${MAP_FILE}"
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
              echo "Error: Document \"${DOC}\" does not exist or was deleted."
              return 1
            else
              if [ "${ADV_OPT}" == "except_for" ]; then
                SYNC="$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})"
              else
                SYNC="$(echo ${SYNC} | sed 's/BOF='"${DOC}"'.*EOF='"${DOC}"'/ /g; s/  / /g')"
              fi
            fi
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            for DELETE_ITEM in $ITEMS; do
              if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*${DELETE_ITEM}.*EOF=${DOC} | grep -o ${DELETE_ITEM})" ]; then
                echo "ERROR: Item \"${DELETE_ITEM}\" does not exist or was deleted."
                return 1
              else
                local DELETE_MATCH=$( \
                  echo ${SYNC} | \
                  sed 's/.*BOF='"${DOC}"'.*\('"${DELETE_ITEM}"':\\\".*\\\"\).*EOF='"${DOC}"'.*/\1/g' \
                )
                if [ "${ADV_OPT}" == "except_for" ]; then
                  if [ -z "${KEEP_ITEMS}" ]; then
                    KEEP_ITEMS="${DELETE_MATCH}"
                  else
                    KEEP_ITEMS="${KEEP_ITEMS} ${DELETE_MATCH}"
                  fi
                else
                  SYNC="$(echo ${SYNC} | sed 's/\(.*BOF='"${DOC}"'.*\)\('"${DELETE_MATCH}"'\)\(.*EOF='"${DOC}"'.*\)/\1 \3/g; s/  / /g')"
                fi
              fi
            done
            if [ "${ADV_OPT}" == "except_for" ] && [ ! -z "${KEEP_ITEMS}" ]; then
              SYNC="$( \
                echo ${SYNC} | \
                sed 's/\(.*BOF='"${DOC}"'\).*\(EOF='"${DOC}"'.*\)/\1 '"${KEEP_ITEMS}"' \2/g; s/  / /g'
              )"
            fi
          fi
        else
          echo "ERROR: Unknown action \"${CRUD}\"."
          return 1
        fi
      # ............................................................Put resulting SYNC data into pipe once, after data mutation.
      if [ $IS_FD -eq 1 ]; then
        printf '%s\n' $SYNC 'EOP' ' ' >&"${PIPE_ADDRESS}"
      else
        printf '%s\n' $SYNC 'EOP' ' ' >> "$(echo ${PIPE_ADDRESS} | base64 -d)"
      fi
    fi
  fi
}