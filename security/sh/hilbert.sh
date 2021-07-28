#!/bin/sh
# Recursive implementation of Hilbert Curve.
# Obfuscates plain text at the binary level.

hilbert () {
  local LOG_ENABLED=
  local LOG_FILE=
  local LOG_INDENT=
  local TB="$( echo -e "\xC2\xA0\xC2\xA0" )"                                      # Double non-breaking space instead of tab (\t).
  local EXPORT_BASE64=
  local SHOW_USAGE=
  local DECODE_DATA=
  local SUBSHELL_FLAGS=
  local STATE=
  local DATA=
  local DATA_TO_BIN=
  #
  # PARSE ARGUMENTS # ----------------------------------------------------------- #
  #
  if [ $( echo -n "$@" | wc -w ) -eq 0 ]; then                                    # If no arguments were passed in...
    [ -z "${SHOW_USAGE}" ] && SHOW_USAGE=1                                        # ...Show the user how to use this script correctly.
  else                                                                            # If we have received arguments...
    for OPT in $@; do                                                             # ...Examine each argument as OPT.
      if [ "${OPT:0:1}" = "-" ]; then                                             # If the first character in OPT is a space...
        if [ "${OPT}" = "-h" ] || [ "${OPT}" = "--help" ]; then                   # ...OPT is an option flag, so check to see if it's a help request.
          if [ -z "${SHOW_USAGE}" ]; then                                         # If OPT is a help request and SHOW_USAGE is empty...
            SHOW_USAGE=1                                                          # ...Latch into help mode by assigning 1 to SHOW_USAGE.
          fi
        fi

        if [ -z "${SHOW_USAGE}" ]; then                                           # IF AND ONLY IF the user has not requested help...
          case $OPT in                                                            # ...Parse the other arguments, if any.
            -l|--log)                                                             # If the user has requested logging...
              if [ -z "${LOG_ENABLED}" ]; then                                    # ...And if LOG_ENABLED is empty...
                LOG_ENABLED=1                                                     # ...Latch into logging mode by assigning 1 to LOG_ENABLED.
                SUBSHELL_FLAGS="${SUBSHELL_FLAGS} --log"                          # ...Also, append --log to SUBSHELL_FLAGS to enable recursive log
                                                                                  #    entries.

                if [ ! -z "${HILBERT_LVL}" ]; then                                # IF AND ONLY IF we are NOT on the root level of recursion...
                  LOG_FILE=$( ls -t /var/log/hilbert*.log | head -n 1 )           # ...LOG_FILE points to the most recently generated log file.

                  until [ ${#LOG_INDENT} -eq $(( $HILBERT_LVL * 2 )) ]; do        # ...Also, LOG_INDENT is interpolated based on level of recursion
                                                                                  #    for formatting purposes.
                    LOG_INDENT="${LOG_INDENT}${TB}"                               # LOG_INDENT uses multiples of two non-breaking spaces (TB).
                  done

                  printf "${LOG_INDENT}%s\n" \
                  "-- SUBSHELL LOG: START -- LEVEL ${HILBERT_LVL} -- $( date -R ) --" \
                  "" >> $LOG_FILE                                                 # Append our indented 'start of log' message to the log.
                else                                                              # IF AND ONLY IF we are on the root level of recursion...
                  LOG_FILE="/var/log/hilbert_$( date +'%Y_%m_%d_%H_%M_%S.log' )"  # ...Create a log file named using date information from the moment
                                                                                  #    of initialization.
                  touch $LOG_FILE
                  chown root:root $LOG_FILE

                  printf "${LOG_INDENT}%s\n" \
                  "-- START OF LOG -- $( date -R ) --" \
                  "" >> $LOG_FILE                                                 # Append our 'start of log' message to the log.
                fi
                printf "${LOG_INDENT}%s\n" \
                "User has not requested help; processing of incoming arguments can proceed." \
                "User has requested the creation of this log file." \
                "${TB}LOG_ENABLED=${LOG_ENABLED}" \
                "${TB}SUBSHELL_FLAGS=${SUBSHELL_FLAGS}" >> $LOG_FILE              # Append diagnostic information to the log relating to logging mode.
              fi
              ;;
            -d|--decode)                                                          # If the user has requested logging...
              if [ -z "${DECODE_DATA}" ]; then                                    # ...And if DECODE_DATA is empty...
                DECODE_DATA=1                                                     # ...Latch into decoding mode by assigning 1 to DECODE_DATA.
                SUBSHELL_FLAGS="${SUBSHELL_FLAGS} --decode"                       # ...Also, append --decode to SUBSHELL_FLAGS to enable recursive
                                                                                  #    decoding.

                if [ ! -z "${LOG_ENABLED}" ]; then                                # If logging mode is latched...
                  printf "${LOG_INDENT}%s\n" \
                  "User has requested decoding of incoming data." \
                  "${TB}DECODE_DATA=${DECODE_DATA}" \
                  "${TB}SUBSHELL_FLAGS=${SUBSHELL_FLAGS}" >> $LOG_FILE            # ...Append diagnostic information to the log relating to decoding mode.
                fi
              fi
              ;;
            -a|--base64)                                                          # If the user has requested base64 encoding of final output...
              if [ -z "${EXPORT_BASE64}" ]; then                                  # ...And if EXPORT_BASE64 is empty...
                EXPORT_BASE64=1                                                   # ...Latch into base64 encoding mode by assigning 1 to EXPORT_BASE64.

                if [ ! -z "${LOG_ENABLED}" ]; then                                # If logging mode is latched...
                  printf "${LOG_INDENT}%s\n" \
                  "User has requested base64-encoding of final output." \
                  "${TB}EXPORT_BASE64=${EXPORT_BASE64}" >> $LOG_FILE              # Append diagnostic information to the log relating to base64-encoding mode.
                fi
              fi
              ;;
          esac
        fi
      else                                                                        # If the first character in OPT is NOT a space...
        DATA="${DATA} ${OPT}"                                                     # ...OPT is a piece of data that must be collected by appending
                                                                                  #    it inside of DATA.
      fi
    done                                                                          # All incoming arguments have been consumed by the function.

    if [ -z "${SHOW_USAGE}" ]; then                                               # If the user has NOT requested help, we can execute function body.

      if [ ! -z "${LOG_ENABLED}" ]; then
        printf "${LOG_INDENT}%s\n" \
        "User has NOT requested help or made an error." \
        "Proceeding with data processing." \
        "" >> $LOG_FILE
      fi

      [ "${DATA:0:1}" = " " ] && DATA="${DATA:1}"
      
      if [ ! -z "${LOG_ENABLED}" ]; then                                          # If logging mode is latched...
        printf "${LOG_INDENT}%s\n" \
        "User passed in the following data:" \
        "${TB}DATA=${DATA}" \
        "${TB}#DATA=${#DATA}" \
        "" \
        "-- BEGIN: Data formatting." >> $LOG_FILE                                 # ...Append diagnostic information to the log relating to contents
                                                                                  #    of DATA.
      fi

      local CHK_BIN="$( \
        echo -n "${DATA}" | \
        tr -d '\n' | \
        sed 's|^[0-1]\{1,\}$||' \
      )"

      if [ -z "${HILBERT_LVL}" ]; then                                            # IF AND ONLY IF we are on the root level of recursion...
        local CHK_B64="$( \
          echo -n "${DATA}" | \
          tr -d '\n' | \
          sed 's|^[[^ ][0-9A-Za-z/+=]]\{4,\}$||' \
        )"                                                                        # ...Look for the presence of base64 encoding.
        if [ -z "${CHK_B64}" ] && [ $(( ${#DATA} % 4 )) -eq 0 ]; then
          DATA="$( echo -n "${DATA}" | base64 -d )"                               # Decode base64, if found, and update contents of DATA.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Incoming base64-encoded data detected." \
            "Base64 data has been decoded." \
            "${TB}DATA=${DATA}" >> $LOG_FILE
          fi
        fi

        local CHK_HEX="$( \
          echo -n "${DATA}" | \
          tr -d '\n' | \
          tr [:lower:] [:upper:] | \
          sed 's|^[0-9A-F]\{2,\}$||' \
        )"                                                                        # ...Look for the presence of hexadecimal formatting.
        if [ -z "${CHK_HEX}" ] && [ $(( ${#DATA} % 2 )) -eq 0 ]; then             # If we detect verified hexadecimal data...
          if [ -z "${DECODE_DATA}" ]; then
            DATA="$( \
              echo -n "${DATA}" | \
              xxd -r -ps | \
              iconv -f UTF-8 -t UTF-32LE | \
              xxd -b -c 1 | \
              awk '{ print $2 }' | \
              tr -d '\n' \
            )"                                                                    # ...Reverse postscript hexadecimal, if found, and update contents
                                                                                  #    of DATA.
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "Incoming hexadecimal-formatted data detected." \
              "Hexadecimal has been reversed and postscripted." \
              "Reverse postscript data converted to UTF-32LE." \
              "UTF-32LE converted immediately to binary to prevent data loss." \
              "${TB}DATA=${DATA}" >> $LOG_FILE
            fi
          else
            DATA="$( \
              echo -n "${DATA}" | \
              xxd -r -ps | \
              xxd -b -c 1 | \
              awk '{ print $2 }' | \
              tr -d '\n' \
            )"

            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "Incoming hexadecimal-formatted data detected." \
              "Hexadecimal has been reversed and postscripted." \
              "Reverse postscript data converted immediately to binary to prevent data loss." \
              "${TB}DATA=${DATA}" >> $LOG_FILE
            fi
          fi

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Incoming data has been parsed into binary bits." \
            "All bits concatenated into a single binary string." \
            "${TB}DATA=${DATA}" >> $LOG_FILE
          fi
        fi

        local CHK_UTF="$( \
          echo -n "${DATA}" | \
          tr -d '\n' | \
          sed '
          s|^[[^ ][0-9A-Za-z/+=]]\{4,\}$||;
          s|^[0-9A-F]\{2,\}$||;
          s|^[0-1]\{1,\}$||;
          ' \
        )"                                                                        # ...Look for the presence of UTF-8 text (truthy when all other
                                                                                  #    formats fail to be found).
        if [ ! -z "${CHK_UTF}" ]; then                                            # If we detect UTF-8 string data...
          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Incoming interpreted UTF-8 characters detected." >> $LOG_FILE
          fi

          if [ -z "${DECODE_DATA}" ]; then
            DATA="$( \
              echo -n "${DATA}" | \
              iconv -f UTF-8 -t UTF-32LE | \
              xxd -b -c 1 | \
              awk '{ print $2 }' | \
              tr -d '\n' \
            )"

            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "User has NOT requested decoding:" \
              "${TB}Strict requirement satisfied." \
              "Interpreted UTF-8 characters converted to UTF-32LE." \
              "UTF-32LE converted immediately to binary to prevent data loss." \
              "${TB}DATA=${DATA}" >> $LOG_FILE
            fi
          else
            DATA="$( \
              echo -n "${DATA}" | \
              xxd -b -c 1 | \
              awk '{ print $2 }' | \
              tr -d '\n' \
            )"                                                                    # ...Sanitize, convert to lossless format, and export as binary
                                                                                  #    any UTF-8 text found.
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "Interpreted UTF-8 characters converted immediately to binary to prevent data loss." \
              "${TB}DATA=${DATA}" >> $LOG_FILE
            fi
          fi

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Incoming data has been parsed into binary bits." \
            "All bits concatenated into a single binary string." \
            "${TB}DATA=${DATA}" >> $LOG_FILE
          fi
        fi

        CHK_BIN="$( \
          echo -n "${DATA}" | \
          tr -d '\n' | \
          sed 's|^[0-1]\{1,\}$||' \
        )"                                                                        # ...Look for the presence of binary formatting after parsing of
                                                                                  #    UTF-8.
        if [ -z "${CHK_BIN}" ] && [ $(( ${#DATA} % 8 )) -eq 0 ]; then             # If we detect verified binary data...
          [ -z "${DATA_TO_BIN}" ] && DATA_TO_BIN=1                                # ...Inform the script that data has been processed all the way to
                                                                                  #    binary successfully.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Presence of final binary string confirmed." \
            "Script informed of successful completion of data processing." \
            "${TB}DATA=${DATA}" \
            "${TB}#DATA=${#DATA}" \
            "${TB}DATA_TO_BIN=${DATA_TO_BIN}" >> $LOG_FILE
          fi
        fi
      else                                                                        # IF AND ONLY IF we are NOT on the root level of recursion...
        if [ -z "${CHK_BIN}" ]; then                                              # ...Look for the presence of binary formatting (from initialization
                                                                                  #    of CHK_BIN).
          [ -z "${DATA_TO_BIN}" ] && DATA_TO_BIN=1                                # Inform the script that data has been processed all the way to
                                                                                  # binary successfully.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Presence of binary data confirmed on recursive level ${HILBERT_LVL}." \
            "Script informed of successful receipt of binary data." \
            "${TB}DATA=${DATA}" \
            "${TB}#DATA=${#DATA}" \
            "${TB}DATA_TO_BIN=${DATA_TO_BIN}" \
            "" >> $LOG_FILE
          fi
        fi
      fi

      if [ ! -z "${LOG_ENABLED}" ]; then
        printf "${LOG_INDENT}%s\n" \
        "-- END: Data formatting." >> $LOG_FILE
      fi

      #
      # HANDLE FATAL EXCEPTION # ------------------------------------------------ #
      #
      if [ -z "${DATA_TO_BIN}" ]; then                                            # If binary was not produced from the above parsing...
        if [ ! -z "${DATA}" ]; then                                               # ...And if the user passed in data to encode or decode... 
          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "-- FATAL -- Failed to parse data into final binary format. --" \
            "-- Halting script. -- $( date -R ) --" \
            "${TB}DATA=${DATA}" \
            "" >> $LOG_FILE
          fi

          echo -e "\033[1;37m\033[41m ERROR \033[0m unknown data error: conversion to binary failed."
          return 1                                                                # ...This is a fatal exception, so error out at this point.
        else                                                                      # If data is empty...
          [ -z "${SHOW_USAGE}" ] && SHOW_USAGE=1                                  # ...This is most likely a user error, so latch into help mode to
                                                                                  #    educate them.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "-- USER ERROR -- Failed to pass data into function, or syntax error. --" \
            "-- Showing user help message. -- $( date -R ) --" \
            "" >> $LOG_FILE
          fi
        fi
      fi
      #
      # LOCAL VARIABLES # ------------------------------------------------------- #
      #
      local SC=11                                                                 # Set global floating point precision of decimals.
      
      local PI_CONST=3.141592653589793                                            # Approximation of Pi.
      local RAD_CONST=$( echo "scale=${SC}; ${PI_CONST} / 180" | bc -l )          # Conversion from degree to radian.
      local ROOT_2=$( echo "scale=${SC}; sqrt(2)" | bc -l )                       # Square root of 2.
      local HALF_ROOT_2=$( echo "scale=${SC}; ${ROOT_2} / 2" | bc -l )            # Square root of 2, divided by 2.

      local DATA_LVL=${HILBERT_LVL:-'0'}                                          # Track recursive depth within each subshell. 
      local PT0_ANGLE=${HILBERT_PT0_ANGLE:-'225'}                                 # Parent subshell's starting angle for plotting points.
      local ANGLE_STEP=90                                                         # Angle of incrementation from point to point.
      local ANGLE_STEP_SCALAR=${HILBERT_SCALAR:-'-1'}                             # Scalar value of +/-1 (determines cw or ccw rotation).

      local n=0                                                                   # Nth power that 4 is raised to.
      local SIZE=                                                                 # Result of (4 ** n); size of Hilbert Curve.
      
      if [ ! -z "${LOG_ENABLED}" ]; then
        printf "${LOG_INDENT}%s\n" \
        "Local variables and constants initialized." >> $LOG_FILE

        printf "${LOG_INDENT}${TB}%s\n" \
        "SC=${SC}" \
        "PI_CONST=${PI_CONST}" \
        "RAD_CONST=${RAD_CONST}" \
        "ROOT_2=${ROOT_2}" \
        "HALF_ROOT_2=${HALF_ROOT_2}" \
        "DATA_LVL=${DATA_LVL}" \
        "PT0_ANGLE=${PT0_ANGLE}" \
        "ANGLE_STEP=${ANGLE_STEP}" \
        "ANGLE_STEP_SCALAR=${ANGLE_STEP_SCALAR}" \
        "n=${n}" \
        "SIZE=${SIZE}" \
        "" >> $LOG_FILE
      fi

      #
      # DYNAMIC RESIZING # ---------------------------------------------------- #
      #
      if [ ! -z "${LOG_ENABLED}" ]; then
        printf "${LOG_INDENT}%s\n" \
        "Dynamically resizing Hilbert Curve to contain incoming binary data." >> $LOG_FILE
      fi

      while [ -z "${SIZE}" ] || [ $SIZE -lt ${#DATA} ]; do                        # Calculate nearest Hilbert Curve that can contain our data to be
                                                                                  # encoded.
        SIZE=$(( 4 ** $n ))
        n=$(( $n + 1 ))

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}${TB}%s\n" \
          "SIZE=${SIZE}" >> $LOG_FILE
        fi

      done

      if [ -z "${HILBERT_LVL}" ]; then                                            # IF AND ONLY IF we are on the root level of recursion...

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}%s\n" \
          "" \
          "Root level of recursion:" \
          "${TB}Strict requirement satisfied." \
          "" >> $LOG_FILE
        fi

        if [ -z "${DECODE_DATA}" ]; then                                          # ...And IF AND ONLY IF we are encoding into a new Hilbert Curve...
          local DIFF=$(( $SIZE - ${#DATA} ))                                      # ...Measure the difference between the data to encode and the
                                                                                  #    curve's size (if any).
          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Potential difference of size between data and curve has been measured." \
            "${TB}DIFF=${DIFF}" \
            "" >> $LOG_FILE
          fi

          if [[ $DIFF -gt 0 && $DIFF -ge 32 ]]; then                              # If there is a difference that is at least 32-bits long...
            DATA="${DATA}$( \
              echo -en "\xF4\x8F\xBF\xBF" | \
              xxd -b -c 1 | \
              awk '{ print $2 }' | \
              tr -d '\n' \
            )"                                                                    # ...Append our custom 'end of text' character (U+10FFFF).
            DIFF=$(( $SIZE - ${#DATA} ))                                          # ...Recalculate the size difference (if any).
            
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}%s\n" \
              "Appended unicode code point U+10FFFF to DATA." \
              "Recalculated size difference." \
              "${TB}DATA=${DATA}" \
              "${TB}DIFF=${DIFF}" \
              "" >> $LOG_FILE
            fi
          fi

          if [ $DIFF -gt 0 ]; then                                                # If there is still a difference in size after appending U+10FFFF...
            local MULTIPLE_OF_8="$( \
              echo "scale=${SC}; ${DIFF} / 8" | \
              bc -l | \
              sed "s|[.0-0]\{$(( ${SC} + 1 ))\}||" | \
              grep -o '\.' \
            )"                                                                    # ...Check for a multiple of 8 (truthy returns empty string, falsey
                                                                                  #    returns decimal point).
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}%s\n" \
              "A difference of size remains after appending U+10FFFF." \
              "${TB}DIFF=${DIFF}" \
              "Measuring difference to see if it contains a multiple of 8." \
              "" >> $LOG_FILE
            fi

            if [ -z "${MULTIPLE_OF_8}" ]; then                                    # If a multiple of 8 was detected...
              local FOLD_W=$(( ( $DIFF / 8 ) - 1 ))                               # ...Solve for the multiplier.
              if [ $FOLD_W -gt 0 ]; then
                DATA="${DATA}$( \
                  tr -cd [[:alnum:][:punct:]] < /dev/random | \
                  fold -w ${FOLD_W} | \
                  head -n 1 | \
                  xxd -b -c 1 | \
                  awk '{ print $2 }' | \
                  tr -d '\n' \
                )"                                                                # ...Append random characters as binary bytes to pad the rest of the
                                                                                  #    curve.
                DIFF=$(( $SIZE - ${#DATA} ))

                if [ ! -z "${LOG_ENABLED}" ]; then
                  printf "${LOG_INDENT}%s\n" \
                  "Difference of size contains a multiple of 8." \
                  "${TB}FOLD_W=${FOLD_W}" \
                  "Appended random bytes to pad remainder of curve." \
                  "${TB}DATA=${DATA}" \
                  "" >> $LOG_FILE
                fi

              fi
            fi
          fi

          if [ $DIFF -gt 0 ]; then

            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}%s\n" \
              "A difference of size remains after appending bytes." \
              "${TB}DIFF=${DIFF}" \
              "Measuring difference to see how many bits remain." \
              "" >> $LOG_FILE
            fi

            if [ $DIFF -lt 8 ]; then                                              # ...And if the difference is less than 8...
              DATA="${DATA}$( \
                tr -cd [0-1] < /dev/random | \
                fold -w ${DIFF} | \
                head -n 1 | \
                tr -d '\n' \
              )"                                                                  # ...Append random bits to pad the rest of the curve.
              
              if [ ! -z "${LOG_ENABLED}" ]; then
                printf "${LOG_INDENT}%s\n" \
                "Difference of size is not divisble by 8." \
                "${TB}DIFF=${DIFF}"
                "Appended random bits to pad remainder of curve." \
                "${TB}DATA=${DATA}" \
                "" >> $LOG_FILE
              fi
            fi
          fi
        fi
      fi
      #
      # TRIGONOMETRY # ---------------------------------------------------------- #
      #
      local FOURTH_DATA_LEN=$(( ${#DATA} / 4 ))                                   # Length of our final data, divided by four (passed into subshells).
      local ROOT_N=$( echo "scale=${SC}; sqrt(${SIZE})" | bc -l )                 # The side length of the square region filled by this Hilbert Curve.
      local HALF_SIZE=$( echo "scale=${SC}; ${ROOT_N} / 2" | bc -l )              # Half of the side length used to plot this Hilbert Curve.
      local CENTER_X=$( \
        echo "scale=${SC}; ${HILBERT_X_OFFSET:-$HALF_SIZE}" | \
        bc -l \
      )                                                                           # Point of origin x-coordinate for this level of recursion (float).
      local CENTER_Y=$( \
        echo "scale=${SC}; ${HILBERT_Y_OFFSET:-$HALF_SIZE}" | \
        bc -l \
      )                                                                           # Point of origin y-coordinate for this level of recursion (float).
      local RADIUS=$( \
        echo "scale=${SC}; ( ${HALF_SIZE} / 2 ) * ${ROOT_2}" | \
        bc -l \
      )                                                                           # Radius used to solve for points located on next deeper level of
                                                                                  # recursion.
      if [ ! -z "${LOG_ENABLED}" ]; then
        printf "${LOG_INDENT}%s\n" \
        "Trigonometric variables calculated." >> $LOG_FILE

        printf "${LOG_INDENT}${TB}%s\n" \
        "FOURTH_DATA_LEN=${FOURTH_DATA_LEN}" \
        "ROOT_N=${ROOT_N}" \
        "HALF_SIZE=${HALF_SIZE}" \
        "CENTER_X=${CENTER_X}" \
        "CENTER_Y=${CENTER_Y}" \
        "RADIUS=${RADIUS}" \
        "" >> $LOG_FILE
      fi

      if [ -z "${HILBERT_LVL}" ]; then                                            # IF AND ONLY IF we are on the root level of recursion...

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}%s\n" \
          "Root level of recursion:" \
          "${TB}Strict requirement satisfied." \
          "" >> $LOG_FILE
        fi

        if [ -f /tmp/.hilbert ]; then                                             # ...And if a previous temporary file exists...
          rm -f /tmp/.hilbert                                                     # ...Remove the previous temporary file.
          
          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Removed previous temporary file." \
            "" >> $LOG_FILE
          fi
        fi

        touch /tmp/.hilbert                                                      # Create a new completely empty temporary file.
        chown root:root /tmp/.hilbert

        local LINE=1; local LINE_MAX="$( echo -n "${ROOT_N}" | sed 's|^\([0-9]\{1,\}\)[.]\{1\}.*$|\1|' )";

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}%s\n" \
          "Calculated line count of new temporary file." \
          "${TB}LINE=${LINE}" \
          "${TB}LINE_MAX=${LINE_MAX}" \
          "" >> $LOG_FILE
        fi
        
        while [ $LINE -le $LINE_MAX ]; do                                         # Iterate across line count for the new temporary file.
          if [ ! -z "${DECODE_DATA}" ]; then                                      # If we are decoding an incoming encoded string...
            local LINE_STR="${DATA:$(( ( $LINE - 1 ) * $LINE_MAX )):$LINE_MAX}"
            printf '%s\n' "${LINE_STR}" >> /tmp/.hilbert                          # ...Parse encoded data back into temporary file.
            
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}%s\n" \
              "Placed encoded data into line ${LINE} of new blank temporary file." \
              "${TB}LINE_STR=${LINE_STR}" >> $LOG_FILE
            fi

          else                                                                    # If we are encoding into a new Hilbert Curve...
            local BLANK_STR="$( printf "%0${LINE_MAX}s" " " )"
            echo "${BLANK_STR}" >> /tmp/.hilbert                         # ...Lines within new temporary file are empty by default.
            
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}%s\n" \
              "Placed blank string with length ${LINE_MAX} into line ${LINE} of new blank temporary file." \
              "${TB}BLANK_STR=\"${BLANK_STR}\"" >> $LOG_FILE
            fi

          fi
          LINE=$(( $LINE + 1 ))                                                   # Increment the line number.
        done
      fi

      local I=0; local J=0; local K=3;

      if [ ! -z "${LOG_ENABLED}" ]; then
        printf "${LOG_INDENT}%s\n" \
        "-- BEGIN: Iteration across items." >> $LOG_FILE
      fi

      while [[ $I -ge $J && $I -le $K ]]; do                                      # Iterate across items (subshells / character x,y pairs)
        local DRAW_DEGREES=$(( $PT0_ANGLE + ( $ANGLE_STEP_SCALAR * $I * $ANGLE_STEP ) ))

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}${TB}%s\n" \
          "Calculated draw degrees for location of item ${I}." \
          "${TB}DRAW_DEGREES=${DRAW_DEGREES}" >> $LOG_FILE
        fi

        case $I in                                                                # Look for edge cases within items.
          $J)                                                                     # First item edge case.
            local INHERITED_ANGLE=$(( $PT0_ANGLE + ( $ANGLE_STEP_SCALAR * 360 ) ))
            local INHERITED_SCALAR=$(( -1 * $ANGLE_STEP_SCALAR ))
            
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "First item edge case detected." \
              "Calculated angle and scalar values to be consumed by a spawned subshell." \
              "${TB}INHERITED_ANGLE=${INHERITED_ANGLE}" \
              "${TB}INHERITED_SCALAR=${INHERITED_SCALAR}" \
              "" >> $LOG_FILE
            fi

            ;;
          $K)                                                                     # Last item edge case.
            local INHERITED_ANGLE=$(( ( -1 * $PT0_ANGLE ) - 90 ))
            local INHERITED_SCALAR=$(( -1 * $ANGLE_STEP_SCALAR ))
            
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "Last item edge case detected." \
              "Calculated angle and scalar values to be consumed by a spawned subshell." \
              "${TB}INHERITED_ANGLE=${INHERITED_ANGLE}" \
              "${TB}INHERITED_SCALAR=${INHERITED_SCALAR}" \
              "" >> $LOG_FILE
            fi

            ;;
          *)                                                                      # Standard case for middle items.
            local INHERITED_ANGLE=$(( $DRAW_DEGREES + ( ( -1 * $ANGLE_STEP_SCALAR ) * $I * 90 ) ))
            local INHERITED_SCALAR=$ANGLE_STEP_SCALAR
            
            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "Middle item standard case detected." \
              "Calculated angle and scalar values to be consumed by a spawned subshell." \
              "${TB}INHERITED_ANGLE=${INHERITED_ANGLE}" \
              "${TB}INHERITED_SCALAR=${INHERITED_SCALAR}" \
              "" >> $LOG_FILE
            fi

            ;;
        esac

        local X_DEST=$( \
          echo "scale=${SC}; \
          ${CENTER_X} + ( c( ${DRAW_DEGREES} * ${RAD_CONST} ) * ${RADIUS} )" | \
          bc -l \
        )                                                                         # Solve for x-coordinate as a floating point value.
        
        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}${TB}%s\n" \
          "Calculated x-coordinate of origin point for a spawned subshell." \
          "${TB}X_DEST=${X_DEST}" \
          "" >> $LOG_FILE
        fi

        local Y_DEST=$( \
          echo "scale=${SC}; \
          ${CENTER_Y} + ( s( ${DRAW_DEGREES} * ${RAD_CONST} ) * ${RADIUS} )" | \
          bc -l \
        )                                                                         # Solve for y-coordinate as a floating point value.
        
        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}${TB}%s\n" \
          "Calculated y-coordinate of origin point for a spawned subshell." \
          "${TB}Y_DEST=${Y_DEST}" \
          "" >> $LOG_FILE
        fi
        #
        # RECURSION # ----------------------------------------------------------- #
        #
        if [ "${RADIUS}" = "${HALF_ROOT_2}" ]; then                               # Interpolate encoded character within temporary file.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Bottom level of recursion detected." \
            "${TB}RADIUS=${RADIUS}" \
            "" >> $LOG_FILE
          fi

          X_DEST=$( \
            echo -n "${X_DEST}" | \
            sed 's|^\([.]\{1\}[0-9]\{1,\}\)$|0\1|; s|^\([0-9]\{1,\}\)[.]\{1\}[0-9]\{1,\}$|\1|;' \
          )                                                                       # The integer x-coordinate of our encoded binary bit.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Calculated x-coordinate of character to encode / read fgrom file." \
            "${TB}X_DEST=${X_DEST}" \
            "" >> $LOG_FILE
          fi

          Y_DEST=$( \
            echo -n "${Y_DEST}" | \
            sed 's|^\([.]\{1\}[0-9]\{1,\}\)$|0\1|; s|^\([0-9]\{1,\}\)[.]\{1\}[0-9]\{1,\}$|\1|;' \
          )                                                                       # The integer y-coordinate of our encoded binary bit.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Calculated y-coordinate of character to encode / read fgrom file." \
            "${TB}Y_DEST=${Y_DEST}" \
            "" >> $LOG_FILE
          fi

          local SIDE_LEN=$( wc -l /tmp/.hilbert | cut -d ' ' -f 1 )               # Solve for a given side of the Hilbert Curve's perimeter.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Solved for side length of perimeter filled by the Hilbert Curve." \
            "${TB}SIDE_LEN=${SIDE_LEN}" \
            "" >> $LOG_FILE
          fi

          local LINE_FROM_FILE="$( \
            sed "$(( $SIDE_LEN - $Y_DEST ))q;d" /tmp/.hilbert \
          )"                                                                      # Copy the line we want to edit from our temporary file.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Parsed line $(( $SIDE_LEN - $Y_DEST )) from temporary file." \
            "This line number is the y-coordinate of the destination where this given character will be encoded or read." \
            "${TB}LINE_FROM_FILE=\"${LINE_FROM_FILE}\"" \
            "" >> $LOG_FILE
          fi

          local Q=0; local R=$(( $SIDE_LEN - 1 ));
          if [ ! -z "${DECODE_DATA}" ]; then
            STATE="${STATE}${LINE_FROM_FILE:$X_DEST:1}"                           # Read bits from our temporary file and place them into STATE.

            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "User requested decoding." \
              "Bit ${X_DEST} has been read from our destination y-coordinate data and placed into STATE." \
              "${TB}STATE=${STATE}" \
              "" >> $LOG_FILE
            fi

          else

            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "User has NOT requested decoding." >> $LOG_FILE
            fi

            case $X_DEST in
              $Q)                                                                 # First item edge case.
                LINE_FROM_FILE="${DATA:$I:1}${LINE_FROM_FILE:$(( $X_DEST + 1 ))}"

                if [ ! -z "${LOG_ENABLED}" ]; then
                  printf "${LOG_INDENT}${TB}%s\n" \
                  "First character edge case detected." \
                  "Parsed bit into index ${Q} within the following data:" \
                  "${TB}LINE_FROM_FILE=${LINE_FROM_FILE}" \
                  "" >> $LOG_FILE
                fi

                ;;
              $R)                                                                 # Last item edge case.
                LINE_FROM_FILE="${LINE_FROM_FILE:0:$X_DEST}${DATA:$I:1}"

                if [ ! -z "${LOG_ENABLED}" ]; then
                  printf "${LOG_INDENT}${TB}%s\n" \
                  "Last character edge case detected." \
                  "Parsed bit into index ${R} within the following data:" \
                  "${TB}LINE_FROM_FILE=${LINE_FROM_FILE}" \
                  "" >> $LOG_FILE
                fi

                ;;
              *)                                                                  # Standard case for middle items.
                LINE_FROM_FILE="${LINE_FROM_FILE:0:$X_DEST}${DATA:$I:1}${LINE_FROM_FILE:$(( $X_DEST + 1 ))}"

                if [ ! -z "${LOG_ENABLED}" ]; then
                  printf "${LOG_INDENT}${TB}%s\n" \
                  "Middle character standard case detected." \
                  "Parsed bit into index ${I} within the following data:" \
                  "${TB}LINE_FROM_FILE=${LINE_FROM_FILE}" \
                  "" >> $LOG_FILE
                fi

                ;;
            esac

            sed -i "$(( $SIDE_LEN - $Y_DEST ))s|.*|${LINE_FROM_FILE}|" \
            /tmp/.hilbert                                                        # Overwrite temporary file contents at line $SIDE_LEN.


            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}${TB}%s\n" \
              "Overwrote line $(( $SIDE_LEN - $Y_DEST )) in temporary file with union of x,y pair." \
              "${TB}Contents of temporary file:" \
              "$( cat -n /tmp/.hilbert )" \
              "" >> $LOG_FILE
            fi

          fi
        else

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Spawning subshell with following parameters:" >> $LOG_FILE
          fi

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}${TB}%s\n" \
            "HILBERT_LVL=$(( $DATA_LVL + 1 ))" \
            "HILBERT_PT0_ANGLE=${INHERITED_ANGLE}" \
            "HILBERT_SCALAR=${INHERITED_SCALAR}" \
            "HILBERT_X_OFFSET=$( printf '%0.f' "${X_DEST}" )" \
            "HILBERT_Y_OFFSET=$( printf '%0.f' "${Y_DEST}" )" \
            "" >> $LOG_FILE
          fi

          STATE="${STATE}$( \
            HILBERT_LVL=$(( $DATA_LVL + 1 )); \
            HILBERT_PT0_ANGLE=${INHERITED_ANGLE}; \
            HILBERT_SCALAR=${INHERITED_SCALAR}; \
            HILBERT_X_OFFSET=$( printf '%0.f' "${X_DEST}" ); \
            HILBERT_Y_OFFSET=$( printf '%0.f' "${Y_DEST}" ); \
            hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" $SUBSHELL_FLAGS; \
          )"                                                                      # Capture echoed state from lower levels of recursion.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Bottom level of recursion has not yet been reached." \
            "Captured state from spawned subshell is as follows:" \
            "${TB}STATE=${STATE}" \
            "" >> $LOG_FILE
          fi

        fi


        I=$(( $I + 1 ))                                                           # Increment to next encoded character or next subshell.
      done

      if [ ! -z "${LOG_ENABLED}" ]; then
        printf "${LOG_INDENT}%s\n" \
        "-- END: Iteration across items." >> $LOG_FILE
      fi

      if [ -z "${HILBERT_LVL}" ]; then                                            # IF NAD ONLY IF we are on the root level of recursion...

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}%s\n" \
          "Root level of recursion detected." \
          "All recursive subshells have terminated." \
          "" >> $LOG_FILE
        fi

        local TEMP_DATA=
        if [ ! -z "${DECODE_DATA}" ]; then                                        # ...And IF AND ONLY IF the user has requested decoding...
          TEMP_DATA="$( echo -n "${STATE}" | tr -d '\n' )"                        # ...Format our accumulated STATE as a single line.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "User has requested decoding." \
            "Sourced data from STATE and formatted information as a single string." \
            "${TB}TEMP_DATA=${TEMP_DATA}" \
            "" >> $LOG_FILE
          fi

        else                                                                      # If the user has NOT requested decoding...
          if [ ! -f /tmp/.hilbert ]; then                                         # ...And if the temporary file does NOT exist...

            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}%s\n" \
              "-- FATAL -- Temporary file missing prior to completion of data processing. --" \
              "-- Halting script. -- $( date -R ) --" \
              "" >> $LOG_FILE
            fi

            echo -e "\033[1;37m\033[41m ERROR \033[0m unknown file system error: data lost during processing."
            return 1                                                              # ...This is a fatal exception, so error out at this point.
          else                                                                    # ...And if the temporary file exists...
            TEMP_DATA="$( cat /tmp/.hilbert | tr -d '\n' )"                       # ...Format contents of temporary file as a single line.

            if [ ! -z "${LOG_ENABLED}" ]; then
              printf "${LOG_INDENT}%s\n" \
              "User has NOT requested decoding." \
              "Sourced data from temporary file and formatted information as a single string." \
              "${TB}TEMP_DATA=${TEMP_DATA}" \
              "" >> $LOG_FILE
            fi

          fi
        fi

        local OUTPUT_DATA=
        local FINAL_HEX=
        local BYTE_I=0

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}%s\n" \
          "-- BEGIN: Iterating over binary bytes." >> $LOG_FILE
        fi

        while [ $BYTE_I -lt ${#TEMP_DATA} ]; do                                   # Iterate across the bytes of our data.
          local DATUM="$( \
            printf '%02X' "$( \
              echo -n "ibase=2; ${TEMP_DATA:$BYTE_I:8}" | \
              bc -l \
            )" \
          )"                                                                      # Convert a given binary byte to hexadecimal byte.

          FINAL_HEX="${FINAL_HEX}${DATUM}"

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "Parsed byte of binary into hexadecimal format." \
            "${TB}DATUM=${DATUM}" >> $LOG_FILE
          fi

          BYTE_I=$(( $BYTE_I + 8 ))                                               # Increment to the next 8-bits of our data.
        done

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}%s\n" \
          "FINAL_HEX=${FINAL_HEX}" \
          "" \
          "-- END: Iterating over binary bytes." >> $LOG_FILE
        fi

        if [ ! -z "${DECODE_DATA}" ]; then                                        # IF AND ONLY IF the user has requested decoding...
          local X=0; local Z=${#FINAL_HEX};

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}${TB}%s\n" \
            "User requested decoding." \
            "" \
            "-- BEGIN: Iterating over 32-bit hexadecimal." >> $LOG_FILE
          fi

          while [[ $X -lt $Z ]]; do
            local CHUNK_32="${FINAL_HEX:$X:8}"
            if [ "${CHUNK_32}" = "F48FBFBF" ]; then

              if [ ! -z "${LOG_ENABLED}" ]; then
                printf "${LOG_INDENT}${TB}%s\n" \
                "Detected custom 'end of text' character within hexadecimal." \
                "Halting parsing of any further bytes (inclusive to 'end of text' character)." \
                "${TB}CHUNK_32=${CHUNK_32}" >> $LOG_FILE
              fi

              break
            else
              OUTPUT_DATA="${OUTPUT_DATA}$( echo -n "${CHUNK_32}" | xxd -r -ps | iconv -t UTF-8 )"

              if [ ! -z "${LOG_ENABLED}" ]; then
                printf "${LOG_INDENT}${TB}%s\n" \
                "Reversed and postscripted hexadecimal into UTF-8 from UTF-32LE" \
                "${TB}OUTPUT_DATA=${OUTPUT_DATA}" \
                "" >> $LOG_FILE
              fi

            fi
            X=$(( $X + 8 ))
          done

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "-- END: Iterating over 32-bit hexadecimal." \
            "" >> $LOG_FILE
          fi

          echo -n "${OUTPUT_DATA}" | tr -d '\n'                                   # Echo the final string as UTF-8 with all escape sequences removed.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Echoed final decoded output." \
            "${TB}OUTPUT_DATA=${OUTPUT_DATA}" \
            "" >> $LOG_FILE
          fi

          rm -f /tmp/.hilbert                                                     # Remove previous temporary file to prevent data corruption.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Removed temporary file after completing decoding data processing." \
            "" >> $LOG_FILE
          fi

        else                                                                      # If the user has NOT requested decoding...
          echo -n "${FINAL_HEX}"                                                  # Echo the final hexadecimal string by removing escape sequences
                                                                                  # with sed.
          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Echoed final encoded output." \
            "${TB}FINAL_HEX=${FINAL_HEX}" \
            "" >> $LOG_FILE
          fi

          rm -f /tmp/.hilbert                                                     # Remove previous temporary file to prevent data corruption.

          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "Removed temporary file after completing encoding data processing." \
            "" >> $LOG_FILE
          fi

        fi
      else                                                                        # If we are NOT on the root level of recursion...

        if [ ! -z "${LOG_ENABLED}" ]; then
          printf "${LOG_INDENT}%s\n" \
          "Recursive level beneath root level detected." \
          "STATE will not be echoed to be consumed by higher levels of recursion unless user requests decoding." \
          "" >> $LOG_FILE
        fi

        if [ ! -z "${DECODE_DATA}" ]; then                                        # ...And IF AND ONLY IF the user has requested decoding...
          echo -n "${STATE}" | tr -d '\n'                                         # ...Echo our accumulated STATE without newline characters, to be 
                                                                                  #    consumed by a higher recursion level.
          if [ ! -z "${LOG_ENABLED}" ]; then
            printf "${LOG_INDENT}%s\n" \
            "User has requested decoding." \
            "STATE has been echoed for consumption on a higher level of recursion." \
            "${TB}STATE=${STATE}" \
            "" >> $LOG_FILE
          fi

        fi
      fi
    fi

    if [ ! -z "${SHOW_USAGE}" ]; then                                             # If the user HAS requested help (or if they made a mistake)...
      #
      # DISPLAY HELP / HANDLE SYNTAX ERROR(S) # --------------------------------- #
      #
      echo -e "\033[1;37m\033[42m Usage \033[0m hilbert \"<data>\" [ -d | --decode ] [ -a | --base64 ] [ -h | --help ]\n
      \n\
      -h | --help\t\tDisplay this message.\n\
      \n\
      \"<data>\"\t\tMust be a quoted string during encoding.\n\
      \t\t\tMust be a string in base64, hexadecimal, or binary format during decoding.\n\
      -d | --decode\tEnable data decoding.\n\
      -a | --base64\tDecoded output is encoded using base64."
      return 0                                                                    # Exit gracefully.
    fi
  fi
}
