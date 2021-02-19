#!/bin/sh

display_pipe_crud_usage() {
  echo "pipe_crud usage:"
  echo "" # Breathing space ###########################################################################################
  if [ "${1}" == "c" ] || [ -z "${1}" ]; then
    echo "  Create"
    echo "          Description:  create a new named / secure CRUD pipe, create a new document inside existing CRUD pipe."
    echo "" # Breathing space #########################################################################################
    echo "          Examples:     pipe_crud -c -P=new_empty_pipe"
    echo "                        pipe_crud -c -P=new_pipe -D=empty_doc"
    echo "                        pipe_crud -c -P=new_pipe -D=new_doc -I={\\\"var1\\\":\\\"val1\\\", \\\"var2\\\":\\\"val2\\\"}"
    echo "                        pipe_crud -c -P=sec_pipe -D=sec_doc -I={ ... } --secure"
    echo "" # Breathing space #########################################################################################
    echo "                        NOTE: Escaped quotes (\\\") are required as shown."
    echo "" # Breathing space #########################################################################################
    echo "          Options:      -c|--create       invoke the create CRUD action.  (Required)"
    echo "                        -P|--pipe=        the name of the created pipe.   (Required)"
    echo "                        -D|--doc=         the ID of the created document."
    echo "                        -I|--items=       the items that populate the created document."
    echo "                        --secure          create a secure, air-gapped CRUD pipe."
    echo "                        --overwrite-pipe  overwrite existing data with empty data."
    echo "" # Breathing space #########################################################################################
  fi
  if [ "${1}" == "r" ] || [ -z "${1}" ]; then
    echo "  Read"
    echo "          Description:  read from a named / secure CRUD pipe."
    echo "" # Breathing space #########################################################################################
    echo "          Examples:     pipe_crud -r -P=pipe_name"
    echo "                        pipe_crud -r -P=pipe_name -D=doc_id"
    echo "                        pipe_crud -r -P=pipe_name -D=doc_id -I={\\\"var1\\\", \\\"var2\\\"}"
    echo "                        pipe_crud -r -P=pipe_name -D=doc_id -I={ ... } --delete-after"
    echo "" # Breathing space #########################################################################################
    echo "                        NOTE: Escaped quotes (\\\") are required as shown."
    echo "" # Breathing space #########################################################################################
    echo "          Options:      -r|--read         invoke the read CRUD action.    (Required)"
    echo "                        -P|--pipe=        the name of the pipe to read.   (Required)"
    echo "                        -D|--doc=         the ID of the document to read from."
    echo "                        -I|--items=       the items whose values are to be returned."
    echo "                        --delete-after    delete data after they are read."
    echo "" # Breathing space #########################################################################################
  fi
  if [ "${1}" == "u" ] || [ -z "${1}" ]; then
    echo "  Update"
    echo "          Description:  update existing data within or add new data to a named / secure CRUD pipe."
    echo "" # Breathing space #########################################################################################
    echo "          Examples:     pipe_crud -u -P=pipe_name"
    echo "                        pipe_crud -u -P=pipe_name -D=doc_id"
    echo "                        pipe_crud -u -P=pipe_name -D=doc_id -I={\\\"var1\\\":\\\"val1\\\", \\\"var2\\\":\\\"val2\\\"}"
    echo "                        pipe_crud -u -P=pipe_name -D=doc_id -I={ ... } --replace-all"
    echo "" # Breathing space #########################################################################################
    echo "                        NOTE: Escaped quotes (\\\") are required as shown."
    echo "" # Breathing space #########################################################################################
    echo "          Options:      -u|--update       invoke the update CRUD action.  (Required)"
    echo "                        -P|--pipe=        the name of the pipe to update. (Required)"
    echo "                        -D|--doc=         the ID of the document to update."
    echo "                        -I|--items=       the items whose values are to be updated."
    echo "                        --replace-all     replace contents of update target with update data."
    echo "" # Breathing space #########################################################################################
  fi
  if [ "${1}" == "d" ] || [ -z "${1}" ]; then
    echo "  Delete"
    echo "          Description:  delete a named / secure RUD pipe or data contained inside of it."
    echo "" # Breathing space #########################################################################################
    echo "          Examples:     pipe_crud -d -P=pipe_name"
    echo "                        pipe_crud -d -P=pipe_name -D=doc_id"
    echo "                        pipe_crud -d -P=pipe_name -D=doc_id -I={\\\"var1\\\", \\\"var2\\\"}"
    echo "                        pipe_crud -d -P=pipe_name -D=doc_id -I={ ... } --except-for"
    echo "" # Breathing space #########################################################################################
    echo "                        NOTE: Escaped quotes (\\\") are required as shown."
    echo "" # Breathing space #########################################################################################
    echo "          Options:      -d|--delete       invoke the delete CRUD action.  (Required)"
    echo "                        -P|--pipe=        the name of the pipe to delete. (Required)"
    echo "                        -D|--doc=         the ID of the document to delete."
    echo "                        -I|--items=       the items that the user intends to delete."
    echo "                        --except-for      delete all items except for those specified."
    echo "" # Breathing space #########################################################################################
  fi
}

pipe_crud() {
  local PIPE=
  local DOC=
  local ITEMS=
  local CRUD=
  local ADV_OPT=
  local SYNC=
  # ............................................................... Parse arguments. ##################################
  local look_for_curlies=0
  local open_brace=0
  local close_brace=0
  for arg in "$@"; do
    local cmd=
    local str=
    local chk=
    # ............................................................. We must be confident that we are detecting and parsing the equal sign in the correct format.
    [ ! -z "$(echo ${arg} | sed 's/^[-]\{1,2\}.*\([\=]\{1\}\).*$/\1/g' | grep -o '=')" ] && cmd="$(echo ${arg} | sed 's/^\([-]\{1,2\}[^\=]\{1,\}\)[\=]\{0,1\}\(.*\)$/\1/')" || cmd="${arg}"
    [ ! -z "$(echo ${arg} | sed 's/^[-]\{1,2\}.*\([\=]\{1\}\).*$/\1/g' | grep -o '=')" ] && str="$(echo ${arg} | sed 's/^\([-]\{1,2\}[^\=]\{1,\}\)[\=]\{0,1\}\(.*\)$/\2/')"
    # ............................................................. Conditionally respond to arguments on a first come, first served basis.
    case $cmd in
      -P|--pipe)
        [ -z "${PIPE}" ] && PIPE="${str}"
        ;;
      -D|--doc)
        [ -z "${DOC}" ] && DOC="${str}"
        ;;
      -I|--items) # ............................................... We have parsed the "items" command.
        if [ $look_for_curlies -eq 0 ]; then
          chk="$(echo ${str} | sed 's/^\({\).*/\1/g')" # .......... Look for an opening curly brace.
          if [ ${#chk} -eq 1 ] && [ "${chk}" == "{" ] && [ $open_brace -eq 0 ]; then
            open_brace=1 # ........................................ Inform future iterations that we have found the opening curly brace.
          fi
          chk="$(echo ${str} | sed 's/.*\(}\)$/\1/g')" # .......... Look for a closing curly brace.
          if [ ${#chk} -eq 1 ] && [ "${chk}" == "}" ] && [ $close_brace -eq 0 ]; then
            close_brace=1 # ....................................... Inform the subsequent code below that we have also found the closing curly brace.
          fi
          chk= # .................................................. Reset value of chk to prevent errors.
          if [ $open_brace -eq 0 ] && [ $close_brace -eq 0 ]; then
            echo "ERROR: Incorrect format for incoming item data."
            display_pipe_crud_usage
            return 1 # ............................................ Go no further, user error formatting item data.
          elif [ $open_brace -eq 1 ] && [ $close_brace -eq 0 ]; then
            ITEMS="$(echo ${str} | sed "s/^{\(.*\)/\1/g; s/[\/\&\"\`\$\\]/\\\&/g")"
            look_for_curlies=1 # .................................. Specifically inform future iterations we intend to look for the closing curly brace.
          elif [ $open_brace -eq 1 ] && [ $close_brace -eq 1 ]; then
            ITEMS="$(echo ${str} | sed "s/^{\(.*\)}$/\1/g; s/[\/\&\"\`\$\\]/\\\&/g")"
            open_brace=0
            close_brace=0
            look_for_curlies=-1 # ................................. Place item data into ITEMS and prevent future iterations from handling items in any way.
          fi
        fi
        ;;
      # ........................................................... Only available when creating new pipe.
      --secure)
        [ -z "${ADV_OPT}" ] && ADV_OPT=secure
        ;;
      # ........................................................... Only available when creating new records in existing pipe.
      --overwrite-pipe)
        [ -z "${ADV_OPT}" ] && ADV_OPT=overwrite_pipe
        ;;
      # ........................................................... Only available when reading from existing, populated pipe.
      --delete-after)
        [ -z "${ADV_OPT}" ] && ADV_OPT=delete_after
        ;;
      # ........................................................... Only available when updating existing, populated pipe.
      --replace-all)
        [ -z "${ADV_OPT}" ] && ADV_OPT=replace_all
        ;;
      # ........................................................... Only available when deleting from existing, populated pipe.
      --except-for)
        [ -z "${ADV_OPT}" ] && ADV_OPT=except_for
        ;;
      -c|--create)
        [ -z "${CRUD}" ] && CRUD=create
        ;;
      -r|--read)
        [ -z "${CRUD}" ] && CRUD=read
        ;;
      -u|--update)
        [ -z "${CRUD}" ] && CRUD=update
        ;;
      -d|--delete)
        [ -z "${CRUD}" ] && CRUD=delete
        ;;
      *)
        if [ $look_for_curlies -eq 1 ]; then
          chk="$(echo ${cmd} | sed 's/.*\(}\)$/\1/g')"
          if [ ${#chk} -eq 1 ] && [ "${chk}" == "}" ] && [ $close_brace -eq 0 ]; then
            close_brace=1
          fi
          chk=
          if [ $close_brace -eq 1 ]; then
            ITEMS="${ITEMS} $(echo ${cmd} | sed "s/\(.*\)}$/\1/g; s/[\/\&\"\`\$\\]/\\\&/g")"
            open_brace=0
            close_brace=0
            look_for_curlies=-1 # ................................. Inform the script we are done looking for the closing curly brace.
          else
            # ..................................................... Default behavior while looking for closing curly brace is to append what data we find into ITEMS.
            ITEMS="${ITEMS} $(echo ${cmd} | sed "s/[\/\&\"\`\$\\]/\\\&/g")"
          fi
        else
          echo "Bad argument(s)"
          display_pipe_crud_usage
          return 1
        fi
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
      local MAP_FILE_DIR=/tmp/pcmfd
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
      fi
      # ........................................................... File(s) are now present in MAP_FILE_DIR, the map file might already exist or was just created.
      # ........................................................... Reset MAP_FILE contents.
      MAP_FILE=
      # ........................................................... Search for map file in directory.
      for FILE in ${MAP_FILE_DIR}/*; do
        if [ "$(sed '1q;d' ${FILE} | base64 -d)" == "PIPE_CRUD MAP FILE" ]; then
          # ....................................................... Map file identified.
          MAP_FILE=${FILE}
          break
        fi
      done
      # ........................................................... Handle error if map file is missing.
      if [ -z "${MAP_FILE}" ]; then
        echo "ERROR: Unable to locate map file."
        return 1
      fi
      local PIPE_ADDRESS= # ....................................... Resolves to named pipe or file descriptor where crud pipe is located.
      local PIPE_64="$(echo ${PIPE} | base64)"
      local PIPE_MAP_STRING="${PIPE_64}"
      local IS_FD=0
      # ........................................................... FIFO has not been created yet.
      if [ -z "$(cat ${MAP_FILE} | grep -o ${PIPE_64})" ]; then
        ###############################################################################################################
        if [ "${CRUD}" == "create" ]; then # ...................... CREATE - part 1 ###################################
        ###############################################################################################################
          ##########################################################
          # NOTE:                                                  #
          #       We only check for the advanced option "secure"   #
          #       once during the create crud action, as shown     #
          #       below.                                           #
          #                                                        #
          ##########################################################
          if [ "${ADV_OPT}" == "secure" ]; then
            local _TMP=$( \
              tr -cd a-f0-9 < /dev/urandom | \
              fold -w32 | \
              head -n1 \
            ) # ................................................... Random 16 byte hexadecimal temporary filename of FIFO.
            # ..................................................... Delare variables used to locate available file descriptors.
            local TEST_FD=6
            local LAST_FD=100
            # ..................................................... Iterate over file descriptors.
            while [ $TEST_FD -le $LAST_FD ]; do
              if [ ! -e /proc/$$/fd/$TEST_FD ]; then
                PIPE_ADDRESS=${TEST_FD} # ......................... Next available file descriptor.
                break
              fi
              TEST_FD=$(($TEST_FD + 1))
            done
            # ..................................................... Handle edge case that no FD was found.
            if [ -z "${PIPE_ADDRESS}" ]; then
              echo "ERROR: File descriptor unavailable. Increase value of LAST_FD."
              return 1
            fi
            # ..................................................... Build the secure pipe as follows:
            mkfifo $_TMP
            eval "exec ${PIPE_ADDRESS}<> ${_TMP}"
            unlink $_TMP
            PIPE_MAP_STRING="${PIPE_MAP_STRING} ${PIPE_ADDRESS}"  # Append a new line to our map file that
                                                                  # directs us to use PIPE_ADDRESS when
                                                                  # looking for PIPE.
            if [ $IS_FD -eq 0 ]; then # ........................... Let the rest of the sccript know this
              IS_FD=1                                             # is a secure pipe.
            fi
          else
            PIPE_ADDRESS=$PIPE
            mkfifo "${PIPE_ADDRESS}" # ............................ Create regular, named FIFO.
          fi
          # ....................................................... User is creating a document.
          if [ ! -z "${DOC}" ]; then
            if [ ! -z "${ITEMS}" ]; then # ........................ Document contains items.
              local CREATE_ITEM_NAMES=
              local PROBLEM_FOUND=0
              for CREATE_ITEM in $ITEMS; do
                local PARSED_ITEM_NAME=$( \
                  echo ${CREATE_ITEM} | \
                  sed 's/\(\\\"\)\(.*\)\(\\\":\\\".*\\\"\).*/\2/g' \
                )
                if [ ! -z "$(echo ${CREATE_ITEM_NAMES} | grep -o ${PARSED_ITEM_NAME})" ]; then
                  echo "ERROR: Item name \"${PARSED_ITEM_NAME}\" must be unique within parent document."
                  if [ $PROBLEM_FOUND -eq 0 ]; then
                    PROBLEM_FOUND=1
                    break
                  fi
                else
                  if [ -z "${CREATE_ITEM_NAMES}" ]; then
                    CREATE_ITEM_NAMES="${PARSED_ITEM_NAME}"
                  else
                    CREATE_ITEM_NAMES="${CREATE_ITEM_NAMES} ${PARSED_ITEM_NAME}"
                  fi
                fi
              done
              [ $PROBLEM_FOUND -eq 0 ] && SYNC="BOF=${DOC} ${ITEMS} EOF=${DOC}"
            else # ................................................ Document contains no items.
              SYNC="BOF=${DOC} EOF=${DOC}"
            fi
          # ....................................................... User is only creating a pipe.
          else
            SYNC=
          fi
          ##########################################################
          # NOTE:                                                  #
          #       We use population within the map file to confirm #
          #       existence of the pipe, whether it's in "named    #
          #       pipe" or "file descriptor" format.               #
          #                                                        #
          ##########################################################
          # ....................................................... Populate map file to confirm the pipe was created.
          printf '%s\n' "${PIPE_MAP_STRING}" >> "${MAP_FILE}"
        fi
      #
      else # ...................................................... FIFO has already been created.
      #
        local PIPE_LINE_NUM=1 # ................................... Track the line number where PIPE_64 appears to delete it in the "delete" crud action body.
        # ......................................................... Locate mention of PIPE_64 on unknown line number.
        while IFS= read -r LINE; do
          if [ ! -z "$(echo ${LINE} | grep -o ${PIPE_64})" ]; then
            PIPE_ADDRESS=$(echo $LINE | sed "s/${PIPE_64} \(.*\)/\1/g")
            break
          fi
          PIPE_LINE_NUM=$(($PIPE_LINE_NUM + 1))
        done < "${MAP_FILE}"
        # ......................................................... If erasing digits completely erases PIPE_ADDRESS, the pipe is in a file descriptor.
        if [ -z "$(echo ${PIPE_ADDRESS} | sed 's/[0-9]\{0,\}//g')" ]; then
          if [ $IS_FD -eq 0 ]; then
            IS_FD=1
          fi
        else
          # ....................................................... Decode the named pipe address ahead of time.
          PIPE_ADDRESS="$(echo ${PIPE_ADDRESS} | base64 -d)" 2>/dev/null
        fi
        # ......................................................... Pull all DATA out of the pipe once, before any data mutation.
        if [ $IS_FD -eq 1 ]; then
            while IFS= read -r LINE; do
              if [ ! -z "${LINE}" ]; then
                if [ "${LINE}" == "EOP" ]; then
                  break;
                fi
                if [ -z "${SYNC}" ]; then
                  SYNC="${LINE}"
                else
                  SYNC="${SYNC} ${LINE}"
                fi
              fi
            done <&"${PIPE_ADDRESS}"
        else
            while IFS= read -r LINE; do
              if [ ! -z "${LINE}" ]; then
                if [ "${LINE}" == "EOP" ]; then
                  break
                fi
                if [ -z "${SYNC}" ]; then
                  SYNC="${LINE}"
                else
                  SYNC="${SYNC} ${LINE}"
                fi
              fi
            done < "${PIPE_ADDRESS}"
        fi
        SYNC=$(echo ${SYNC} | sed 's/\(.*\)\([\ ]\{0,1\}EOP.*\)/\1/g') # Strip off the "End of Pipe" notice and trailing space.
        ###############################################################################################################
        if [ "${CRUD}" == "create" ]; then # ...................... CREATE - part 2 ###################################
        ###############################################################################################################
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ "${ADV_OPT}" == "overwrite_pipe" ]; then
              SYNC=
            else
              echo "ERROR: Pipe already exists."
            fi
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ "${ADV_OPT}" == "overwrite_pipe" ]; then
              SYNC="BOF=${DOC} EOF=${DOC}"
            else
              if [ ! -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
                echo "ERROR: Document \"${DOC}\" already exists."
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
              local PROBLEM_FOUND=0
              for CREATE_ITEM in $ITEMS; do
                local PARSED_ITEM_NAME=$( \
                  echo ${CREATE_ITEM} | \
                  sed 's/\(\\\"\)\(.*\)\(\\\"\)\(:\\\".*\\\"\).*/\2/g' \
                )
                if [ ! -z "$(echo ${CREATE_ITEM_NAMES} | grep -o ${PARSED_ITEM_NAME})" ]; then
                  echo "ERROR: Item name \"${PARSED_ITEM_NAME}\" must be unique within parent document."
                  if [ $PROBLEM_FOUND -eq 0 ]; then
                    PROBLEM_FOUND=1
                    break
                  fi
                else
                  if [ -z "${CREATE_ITEM_NAMES}" ]; then
                    CREATE_ITEM_NAMES="${PARSED_ITEM_NAME}"
                  else
                    CREATE_ITEM_NAMES="${CREATE_ITEM_NAMES} ${PARSED_ITEM_NAME}"
                  fi
                fi
              done
              if [ $PROBLEM_FOUND -eq 0 ]; then
                if [ -z "${SYNC}" ]; then
                  SYNC="BOF=${DOC} ${ITEMS} EOF=${DOC}"
                else
                  SYNC="${SYNC} BOF=${DOC} ${ITEMS} EOF=${DOC}"
                fi
              fi
            fi
          fi
        ###############################################################################################################
        elif [ "${CRUD}" == "read" ]; then # ...................... READ ##############################################
        ###############################################################################################################
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            printf '%s\n' ${SYNC}
            if [ "${ADV_OPT}" == "delete_after" ]; then
              SYNC=
            fi
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
              echo "ERROR: Document \"${DOC}\" does not exist or was deleted."
            else
              printf '%s\n' $(echo $SYNC | grep -o BOF=${DOC}.*EOF=${DOC})
              if [ "${ADV_OPT}" == "delete_after" ]; then
                SYNC=$(echo $SYNC | sed 's/BOF='"${DOC}"'.*EOF='"${DOC}"'/ /g; s/  / /g')
              fi
            fi
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            local READ_OUTPUT=
            local PROBLEM_FOUND=0
            for READ_ITEM in $ITEMS; do
              local PARSED_ITEM_NAME=$( \
                echo ${READ_ITEM} | \
                sed 's/\(\\\"\)\(.*\)\(\\\"\).*/\2/g' \
              )
              if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*${PARSED_ITEM_NAME}.*EOF=${DOC} | grep -o ${PARSED_ITEM_NAME})" ]; then
                echo "ERROR: Item \"${PARSED_ITEM_NAME}\" does not exist or was deleted."
                if [ $PROBLEM_FOUND -eq 0 ]; then
                  PROBLEM_FOUND=1
                  break
                fi
              else
                local READ_MATCH=$( \
                  echo "${SYNC}" | \
                  sed 's/^.*BOF='"${DOC}"'.*\\\"'"${PARSED_ITEM_NAME}"'\\\":\\\"\(.*\)\\\".*EOF='"${DOC}"'.*$/\1/g' \
                )
                if [ -z "${READ_OUTPUT}" ]; then
                  READ_OUTPUT="${READ_MATCH}"
                else
                  READ_OUTPUT="${READ_OUTPUT} ${READ_MATCH}"
                fi
                if [ "${ADV_OPT}" == "delete_after" ]; then
                  SYNC="$( \
                    echo ${SYNC} | \
                    sed 's/^\(.*BOF='"${DOC}"'.*\)\(\\\"'"${PARSED_ITEM_NAME}"'\\\":\\\".*\\\"\)\(.*EOF='"${DOC}"'.*\)$/\1 \3/g; s/  / /g' \
                  )"
                fi
              fi
            done
            [ $PROBLEM_FOUND -eq 0 ] && echo $READ_OUTPUT
          fi
        ###############################################################################################################
        elif [ "${CRUD}" == "update" ]; then # .................... UPDATE ############################################
        ###############################################################################################################
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ "${ADV_OPT}" == "replace_all" ]; then
              SYNC=
            else
              echo "ERROR: Nothing to update."
              display_pipe_crud_usage u
            fi
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
              echo "ERROR: Document \"${DOC}\" does not exist or was deleted."
            else
              if [ "${ADV_OPT}" == "replace_all" ]; then
                SYNC="$(echo ${SYNC} | sed 's/\(.*BOF='"${DOC}"'\)\(.*\)\(EOF='"${DOC}"'.*\)/\1 \3/g; s/  / /g')"
              else
                echo "ERROR: Nothing to update."
                display_pipe_crud_usage u
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
                UPDATE_ITEM="$(echo ${UPDATE_ITEM} | sed "s/[\/\&\"\`\$\\]/\\\&/g")"
                SYNC="$( \
                  echo ${SYNC} | \
                  sed 's/^\(.*BOF='"${DOC}"'.*\)\(EOF='"${DOC}"'.*\)$/\1 '"${UPDATE_ITEM}"' \2/g; s/  / /g'
                )" # .............................................. We add items to the target document if no match is found.
              else
                if [ "${ADV_OPT}" == "replace_all" ]; then
                  UPDATE_ITEM="$(echo ${UPDATE_ITEM} | sed "s/[\/\&\"\`\$\\]/\\\&/g")"
                  if [ -z "${UPDATE_NEW_ITEMS}" ]; then
                    UPDATE_NEW_ITEMS="${UPDATE_ITEM}"
                  else
                    UPDATE_NEW_ITEMS="${UPDATE_NEW_ITEMS} ${UPDATE_ITEM}"
                  fi
                else
                  local PARSED_ITEM_VAL=$( \
                    echo ${UPDATE_ITEM} | \
                    sed 's/\(\\\".*\\\":\\\"\)\([[:alnum:][:punct:][\ ]]\{1,\}\)\(\\\"\).*/\2/g' \
                  )
                  SYNC="$( \
                    echo ${SYNC} | \
                    sed 's/^\(.*BOF='"${DOC}"'.*\\\"'"${PARSED_ITEM_NAME}"'\\\":\\\"\)\([[:alnum:][:punct:][\ ]]\{1,\}\)\(\\\".*EOF='"${DOC}"'.*\)$/\1'"${PARSED_ITEM_VAL}"'\3/g' \
                  )" # ............................................ We update the values of items we find matches for.
                fi
              fi
            done
            if [ "${ADV_OPT}" == "replace_all" ] && [ ! -z "${UPDATE_NEW_ITEMS}" ]; then
              SYNC="$( \
                echo ${SYNC} | \
                sed 's/^\(.*BOF='"${DOC}"'\).*\(EOF='"${DOC}"'.*\)$/\1 '"${UPDATE_NEW_ITEMS}"' \2/g; s/  / /g'
              )"
            fi
          fi
        ###############################################################################################################
        elif [ "${CRUD}" == "delete" ]; then # .................... DELETE ############################################
        ###############################################################################################################
          if [ -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ $IS_FD -eq 1 ]; then
              eval "${PIPE_ADDRESS}>&-"
            else
              rm -f "${PIPE_ADDRESS}"
            fi
            sed -i "${PIPE_LINE_NUM}d" "${MAP_FILE}" # .......... Remove line containing address of deleted pipe from map file.
          elif [ ! -z "${DOC}" ] && [ -z "${ITEMS}" ]; then
            if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})" ]; then
              echo "Error: Document \"${DOC}\" does not exist or was deleted."
            else
              if [ "${ADV_OPT}" == "except_for" ]; then
                SYNC="$(echo ${SYNC} | grep -o BOF=${DOC}.*EOF=${DOC})"
              else
                SYNC="$(echo ${SYNC} | sed 's/\(.*\)\(BOF='"${DOC}"'.*EOF='"${DOC}"'\)\(.*\)/\1 \3/g; s/  / /g')"
              fi
            fi
          elif [ ! -z "${DOC}" ] && [ ! -z "${ITEMS}" ]; then
            local KEEP_ITEMS=
            local PROBLEM_FOUND=0
            for DELETE_ITEM in $ITEMS; do
              local PARSED_ITEM_NAME=$( \
                echo ${DELETE_ITEM} | \
                sed 's/\(\\\"\)\(.*\)\(\\\"\).*/\2/g' \
              )
              if [ -z "$(echo ${SYNC} | grep -o BOF=${DOC}.*${PARSED_ITEM_NAME}.*EOF=${DOC} | grep -o ${PARSED_ITEM_NAME})" ]; then
                echo "ERROR: Item \"${PARSED_ITEM_NAME}\" does not exist or was deleted."
                if [ $PROBLEM_FOUND -eq 0 ]; then
                  PROBLEM_FOUND=1
                  break
                fi
              else
                local DELETE_MATCH="$( \
                  echo ${SYNC} | \
                  sed 's/^.*BOF='"${DOC}"'.*\(\\\"'"${PARSED_ITEM_NAME}"'\\\":\\\"[[:alnum:][:punct:]]\{1,\}\\\"[,]\{0,1\}\).*EOF='"${DOC}"'.*$/\1/g' \
                )"
                if [ "${ADV_OPT}" == "except_for" ]; then
                  if [ -z "${KEEP_ITEMS}" ]; then
                    KEEP_ITEMS="${DELETE_MATCH}"
                  else
                    KEEP_ITEMS="${KEEP_ITEMS} ${DELETE_MATCH}"
                  fi
                else
                  SYNC="$( \
                    echo ${SYNC} | \
                    sed 's/^\(.*BOF='"${DOC}"'.*\)\(\\\"'"${PARSED_ITEM_NAME}"'\\\":\\\"[[:alnum:][:punct:]]\{1,\}\\\"[,]\{0,1\}\)\(.*EOF='"${DOC}"'.*\)$/\1 \3/g; s/  / /g' \
                  )"
                fi
              fi
            done
            if [ $PROBLEM_FOUND -eq 0 ]; then
              if [ "${ADV_OPT}" == "except_for" ] && [ ! -z "${KEEP_ITEMS}" ]; then
                SYNC="$( \
                  echo ${SYNC} | \
                  sed 's/^\(.*BOF='"${DOC}"'\).*\(EOF='"${DOC}"'.*\)$/\1 '"${KEEP_ITEMS}"' \2/g; s/  / /g'
                )"
              fi
            fi
          fi
        fi
      fi
      # ........................................................... Put resulting SYNC data into pipe once, after data mutation.
      if [ $IS_FD -eq 1 ]; then
        ( printf '%s\n' $SYNC 'EOP' ' ' >&"${PIPE_ADDRESS}" & )
      else
        ( printf '%s\n' $SYNC 'EOP' ' ' >> "${PIPE_ADDRESS}" & )
      fi
    fi
  fi
}