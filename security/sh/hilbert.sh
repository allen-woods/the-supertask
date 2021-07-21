#!/bin/sh
# Recursive implementation of Hilbert Curve.
# Obfuscates plain text at the binary level.
hilbert () {
  local EXPORT_BASE64=
  local SHOW_USAGE=
  local DECODE_DATA=
  local SUBSHELL_FLAGS=
  local STATE=
  local DATA=
  local DATA_TO_BIN=
  #
  # PARSE ARGUMENTS # --------------------------------------- #
  #
  if [ $( echo -n "${@}" | wc -w ) -eq 0 ]; then                                  # If no arguments were passed in...
    [ -z "${SHOW_USAGE}" ] && SHOW_USAGE=1                                        # ...Show the user how to use this script correctly.
  else                                                                            # If we have received arguments...
    for OPT in "${@}"; do                                                         # ...Examine each argument.
      case $OPT in
        -h|--help)
          [ -z "${SHOW_USAGE}" ] && SHOW_USAGE=1
          ;;
        -d|--decode)                                                              # If we detect that data decoding has been requested...
          if [ -z "${SHOW_USAGE}" ]; then                                         # ...And if the user has not requested help...
            if [ -z "${DECODE_DATA}" ]; then                                      # ...Latch our settings in place for decoding.
              DECODE_DATA=1
              SUBSHELL_FLAGS="--decode"
            fi
          fi
          ;;
        -a|--base64)                                                              # If we detect that base64 output has been requested...
          if [ -z "${SHOW_USAGE}" ]; then                                         # ...And if the user has not requested help...
            if [ -z "${EXPORT_BASE64}" ]; then
              EXPORT_BASE64=1                                                     # ...Latch our settings in place for base64 output.
            fi
          fi
          ;;
        *)                                                                        # If the argument is not an option flag...
          if [ -z "${SHOW_USAGE}" ]; then                                         # ...And if the user has not requested help...
            if [ ! -z "${HILBERT_LVL}" ]; then                                    # ...And if we are not on the root level of recursion...
              local CHK_BIN="$( \
                echo -n "${OPT}" | \
                tr -d '\n' | \
                sed 's|[0-1]\{1,\}||g' \
              )"                                                                  # Check to see if the argument is binary formatted data.
              if [ -z "${CHK_BIN}" ]; then                                        # If we detect incoming binary formatted data...
                [ -z "${DATA}" ] && DATA="${OPT}"                                 # ...Let the binary formatted data pass unchanged and latch the
                                                                                  #    input.
                DATA_TO_BIN=1                                                     # Inform the script we have completed incoming data processing.
              else                                                                # ...Otherwise throw an error if truncated bits are detected.
                echo -e "\033[1;37m\033[41m ERROR \033[0m corrupt binary data on recursion level: ${HILBERT_LVL}."
                return 1
              fi
            else                                                                  # If we are on the root level of recursion...
              local CHK_WHERE="${OPT}"                                            # Place data whose format we will be checking into a variable.

              local CHK_B64="$( \
                echo -n "${CHK_WHERE}" | \
                tr -d '\n' | \
                sed 's|[0-9A-Za-z/+=]\{4,\}||g' \
              )"
              if [ -z "${CHK_B64}" ]; then                                        # If we have detected Base64 encoded information...
                if [ $(( ${#CHK_WHERE} % 4 )) -eq 0 ]; then                       # ...And if the incoming data is encoded into 4 character words...
                  DATA="$( echo -n "${CHK_WHERE}" | base64 -d )"                  # ...Decode and place the result into DATA.
                  CHK_WHERE="${DATA}"                                             # Place our decoded data into the variable whose format we check.
                else                                                              # ...Otherwise throw an error if truncated character words are
                                                                                  #    detected.
                  echo -e "\033[1;37m\033[41m ERROR \033[0m base64 encoded data corrupted."
                  return 1
                fi
              fi

              local CHK_HEX="$( \
                echo -n "${CHK_WHERE}" | \
                tr -d '\n' | \
                tr [:lower:] [:upper:] | \
                sed 's|[0-9A-F]\{2,\}||g' \
              )"
              if [ -z "${CHK_HEX}" ]; then                                        # If we have detected a hexadecimal string...
                if [ $(( ${#CHK_WHERE} % 2 )) -eq 0 ]; then                       # ...And if the incoming data is encoded into 2 character bytes...
                  DATA="$( echo -n "${CHK_WHERE}" | xxd -r -ps )"                 # ...Reverse it into a postscript output and place the result into
                                                                                  #    DATA.
                  CHK_WHERE="${DATA}"                                             # Place our postscript data into the variable whose format we check.
                else                                                              # ...Otherwise throw an error if truncated bytes are detected.
                  echo -e "\033[1;37m\033[41m ERROR \033[0m hexadecimal formatted data corrupted."
                  return 1
                fi
              fi

              local CHK_BIN="$( \
                echo -n "${CHK_WHERE}" | \
                tr -d '\n' | \
                sed 's|[0-1]\{8,\}||g' \
              )"
              if [ -z "${CHK_BIN}" ]; then                                        # If we detect binary information...
                if [ $(( ${#CHK_WHERE} % 8 )) -eq 0 ]; then                       # ...And if the incoming data is encoded into 8-bit bytes...
                  DATA="${CHK_WHERE}"                                             # ...Allow binary to pass with no processing.

                  [ -z "${DATA_TO_BIN}" ] && DATA_TO_BIN=1                        # Inform the script we have completed incoming data processing.
                else                                                              # ...Otherwise throw an error if truncated bits are detected.
                  echo -e "\033[1;37m\033[41m ERROR \033[0m binary formatted data corrupted."
                  return 1
                fi
              else                                                                # If we do not detect binary information...
                DATA="$( \
                  echo -n "${CHK_WHERE}" | \
                  tr -d '\n' \
                )"                                                                # ...Strip newline characters from the incoming data.

                if [ -z "${DECODE_DATA}" ]; then                                  # IF AND ONLY IF we are encoding into a new Hilbert Curve...
                  DATA="$( \
                    echo -n "${DATA}" | \
                    sed 's|[`$"*\]\{1,\}|\\&|g' | \
                    iconv -f UTF-8 -t UTF-32LE \
                  )"                                                              # ...Sanitize the UTF-8 characters that must be escaped to
                                                                                  #    prevent data corruption, then convert UTF-8 over to
                                                                                  #    lossless UTF-32LE to prevent data loss.
                fi

                DATA="$( \
                  echo -n "${DATA}" | \
                  xxd -b -c 1 | \
                  awk '{ print $2 }' | \
                  tr -d '\n' \
                )"                                                                # Lastly, convert characters over to binary words that are
                                                                                  # then concatenated into a final binary string.
                [ -z "${DATA_TO_BIN}" ] && DATA_TO_BIN=1                          # Inform the script we have completed incoming data processing.
              fi
            fi
          fi
          ;;
      esac
    done
  fi
  #
  # HANDLE ERRORS / FATAL EXCEPTIONS # ---------------------- #
  #
  if [ -z "${DATA_TO_BIN}" ]; then
    if [ ! -z "${DATA}" ]; then
      echo -e "\033[1;37m\033[41m ERROR \033[0m unknown data error: conversion to binary failed."
      return 1
    else
      [ -z "${SHOW_USAGE}" ] && SHOW_USAGE=1
    fi
  fi
  
  if [ ! -z "${SHOW_USAGE}" ]; then
    echo -e "\033[1;37m\033[42m Usage \033[0m hilbert \"<data>\" [ -d | --decode ] [ -a | --base64 ] [ -h | --help ]\n\
    \n\
    -h | --help\t\tDisplay this message.\n\
    \n\
    \"<data>\"\t\tMust be a quoted string during encoding.\n\
    \t\t\tMust be a string in base64, hexadecimal, or binary format during decoding.\n\
    -d | --decode\tEnable data decoding.\n\
    -a | --base64\tDecoded output is formatted using base64 encoding."
    return 0
  fi
  #
  # LOCAL VARIABLES # --------------------------------------- #
  #
  local DATA_LEN=${#DATA}                                                         # Capture the length of incoming data.

  local SC=11                                                                     # Set global floating point precision of decimals.
  
  local PI_CONST=3.141592653589793                                                # Approximation of Pi.
  local RAD_CONST=$( echo "scale=${SC}; ${PI_CONST} / 180" | bc -l )              # Conversion from degree to radian.
  local ROOT_2=$( echo "scale=${SC}; sqrt(2)" | bc -l )                           # Square root of 2.
  local HALF_ROOT_2=$( echo "scale=${SC}; ${ROOT_2} / 2" | bc -l )                # Square root of 2, divided by 2.

  local DATA_LVL=${HILBERT_LVL:-'0'}                                                # Track recursive depth within each subshell. 
  local PT0_ANGLE=${HILBERT_PT0_ANGLE:-'225'}                                     # Parent subshell's starting angle for plotting points.
  local ANGLE_STEP=90                                                             # Angle of incrementation from point to point.
  local ANGLE_STEP_SCALAR=${HILBERT_SCALAR:-'-1'}                                 # Scalar value of +/-1 (determines cw or ccw rotation).
  #
  # DYNAMIC RESIZING # -------------------------------------- #
  #
  local n=0                                                                       # Nth power that 4 is raised to.
  local SIZE=                                                                     # Result of (4 ** n); size of Hilbert Curve.
  while [ -z "${SIZE}" ] || [ $SIZE -lt $DATA_LEN ]; do                           # Calculate nearest Hilbert Curve that can contain $DATA.
    SIZE=$(( 4 ** $n ))
    n=$(( $n + 1 ))
  done

  if [ -z "${HILBERT_LVL}" ]; then                                                # IF AND ONLY IF we are on the root level of recursion...
    local DIFF=$(( $SIZE - $DATA_LEN ))                                           # ...Capture the difference between $SIZE and $DATA_LEN (if any).
    if [ $DIFF -gt 0 ]; then                                                      # If we have found a difference greater than zero...
      if [ $DIFF -ge 32 ]; then                                                   # ...And if the difference is at least 32 bits...
        local STOP_BIN=$( \
          echo -en "\xF4\x8F\xBF\xBF" | \
          xxd -b -c 1 | \
          awk '{ print $2 }' | \
          tr -d '\n' \
        )                                                                         # ...Use unicode code point U+10FFFF as a custom "end of text"
                                                                                  #    character.
        DATA="${DATA}${STOP_BIN}"                                                 # Append our "end of text" character.
        DATA_LEN=${#DATA}                                                         # Re-measure length of our appended data.
        DIFF=$(( $SIZE - $DATA_LEN ))                                             # Re-calculate difference in length.
      fi
    fi

    if [ $DIFF -gt 0 ]; then                                                      # If we still have a remaining difference after appending our
                                                                                  # custom "end of text" character...
      local MULTIPLE_OF_8="$( \
        echo "scale=${SC}; ${DIFF} / 8" | \
        bc -l | \
        sed "s|[.0-0]\{$(( ${SC} + 1 ))\}||" | \
        grep -o '\.' \
      )"                                                                          # ...Check to see if the difference is a multiple of 8 bits
                                                                                  #    (will only return blank string if true, decimal point if false).
      if [ -z "${MULTIPLE_OF_8}" ]; then                                          # If we have detected a multiple of 8 bits...
        local FOLD_VALUE=$(( ($DIFF / 8) - 1 ))                                   # ...Calculate the detected multiple of 8 bits minus 1 ($FOLD_VALUE).
        if [ $FOLD_VALUE -ne 0 ]; then                                            # If the value of $FOLD_VALUE is not zero...
          local PADDING_BIN="$( \
            tr -cd [[:alnum:][:punct:]] < /dev/random | \
            fold -w ${FOLD_VALUE} | \
            head -n 1 | \
            xxd -b -c 1 | \
            awk '{ print $2 }' | \
            tr -d '\n' \
          )"                                                                      # ...Generate a string of random characters whose length is equal
                                                                                  #    to $FOLD_VALUE and whose bits will be used to fill the rest of
                                                                                  #    the Hilbert Curve.
          DATA="${DATA}${PADDING_BIN}"                                            # Append our padding character(s).
          DATA_LEN=${#DATA}                                                       # Re-measure length of our padded data.
        fi
      else                                                                        # If we have not detected a multiple of 8 bits...
        local PADDING_BIN="$( \
          tr -cd [0-1] < /dev/random | \
          fold -w ${DIFF} | \
          head -n 1 | \
          tr -d '\n' \
        )"                                                                        # ...Generate a random string of bits to fill the rest of the
                                                                                  #    Hilbert Curve.
        DATA="${DATA}${PADDING_BIN}"                                              # Append our padding character(s).
        DATA_LEN=${#DATA}                                                         # Re-measure length of our padded data.
      fi
    fi
  fi

  local FOURTH_DATA_LEN=$(( $DATA_LEN / 4 ))                                      # Length of our final data, divided by four (passed into subshells).
  
  #
  # TRIGONOMETRY # ------------------------------------------ #
  #

  local ROOT_N=$( echo "scale=${SC}; sqrt(${SIZE})" | bc -l )                     # The side length of the square region filled by this Hilbert Curve.
  local HALF_SIZE=$( echo "scale=${SC}; ${ROOT_N} / 2" | bc -l )                  # Half of the side length used to plot this Hilbert Curve.
  local CENTER_X=$( echo "scale=${SC}; ${HILBERT_X_OFFSET:-$HALF_SIZE}" | bc -l ) # Point of origin x-coordinate for this level of recursion (float).
  local CENTER_Y=$( echo "scale=${SC}; ${HILBERT_Y_OFFSET:-$HALF_SIZE}" | bc -l ) # Point of origin y-coordinate for this level of recursion (float).
  local RADIUS=$( echo "scale=${SC}; ( ${HALF_SIZE} / 2 ) * ${ROOT_2}" | bc -l )  # Radius used to solve for points located on next deeper level of
                                                                                  # recursion.
  
  if [ -z "${HILBERT_LVL}" ]; then                                                # IF AND ONLY IF we are on the root level of recursion...
    [ -f /tmp/.hilbert ] && rm -f /tmp/.hilbert                                   # ...Create the destination file (erase existing if found).
    local LINE=1  
    local LINE_MAX="$( \
      echo -n "${ROOT_N}" | \
      sed 's|^\([0-9]\{1,\}\)[.]\{1\}.*$|\1|' \
    )"

    while [ $LINE -le $LINE_MAX ]; do
      if [ ! -z "${DECODE_DATA}" ]; then                                          # If we are decoding an incoming encoded string...
        local LINE_STR="${DATA:$(( ( $LINE - 1 ) * $LINE_MAX )):$LINE_MAX}"       # ...We need to parse data back into lines within our temporary file.
        printf '%s\n' "${LINE_STR}" >> /tmp/.hilbert
      else                                                                        # If we are encoding into a new Hilbert Curve...
        printf "%0${LINE_MAX}s\n" " " >> /tmp/.hilbert                            # ...Lines within our temporary file are empty by default.
      fi
      LINE=$(( $LINE + 1 ))                                                       # Increment line number.
    done
  fi
  
  local I=0; local J=0; local K=3;                                                # Iterate over points of origin / characters.
  while [[ $I -ge $J && $I -le $K ]]; do                                          # Calculate angles.
    local DRAW_DEGREES=$(( $PT0_ANGLE + ( $ANGLE_STEP_SCALAR * $I * $ANGLE_STEP ) ))
    local INHERITED_ANGLE=
    local INHERITED_SCALAR=
    case $I in
      "${J}")
        [ -z "${INHERITED_ANGLE}" ] && INHERITED_ANGLE=$(( $PT0_ANGLE + ( $ANGLE_STEP_SCALAR * 360 ) ))
        [ -z "${INHERITED_SCALAR}" ] && INHERITED_SCALAR=$(( -1 * $ANGLE_STEP_SCALAR ))
        ;;
      "${K}")
        [ -z "${INHERITED_ANGLE}" ] && INHERITED_ANGLE=$(( ( -1 * $PT0_ANGLE ) - 90 ))
        [ -z "${INHERITED_SCALAR}" ] && INHERITED_SCALAR=$(( -1 * $ANGLE_STEP_SCALAR ))
        ;;
      *)
        [ -z "${INHERITED_ANGLE}" ] && INHERITED_ANGLE=$(( $DRAW_DEGREES + ( ( -1 * $ANGLE_STEP_SCALAR ) * $I * 90 ) ))
        [ -z "${INHERITED_SCALAR}" ] && INHERITED_SCALAR=$ANGLE_STEP_SCALAR
        ;;
    esac
    
    local X_DEST=$( \
      echo "scale=${SC}; \
      ${CENTER_X} + ( \
        c( \
          ${DRAW_DEGREES} * ${RAD_CONST} \
        ) * ${RADIUS} \
      )" | \
      bc -l \
    )                                                                             # Solve for x-coordinate as a floating point value.

    local Y_DEST=$( \
      echo "scale=${SC}; \
      ${CENTER_Y} + ( \
        s( \
          ${DRAW_DEGREES} * ${RAD_CONST} \
        ) * ${RADIUS} \
      )" | \
      bc -l \
    )                                                                             # Solve for y-coordinate as a floating point value.
    #
    # RECURSION # ------------------------------------------- #
    #
    if [ "${RADIUS}" = "${HALF_ROOT_2}" ]; then                                   # Interpolate encoded character within temporary file.
      # =================== #
      #  I M P O R T A N T  #
      # =================== # =============================== #
      #                                                       #
      # There is a major 'gotcha' when using the following    #
      # expression to remove decimals:                        #
      #                                                       #
      #   $( printf '%0.f' "${FLOAT}" ) to remove decimals.   #
      #                                                       #
      # Namely, it rounds the trailing decimals that are      #
      # removed to the nearest integer before returning the   #
      # final value!                                          #
      #                                                       #
      # To prevent rounding, prepend zeroes when needed       #
      # first, then parse out the leading integer to retain   #
      # it.                                                   #
      #                                                       #
      # Sed can be used to do this, as shown below:           #
      #                                                       #
      # ===================================================== #

      X_DEST=$( \
        echo -n "${X_DEST}" | \
        sed 's|^\([.]\{1\}[0-9]\{1,\}\)$|0\1|; s|^\([0-9]\{1,\}\)[.]\{1\}[0-9]\{1,\}$|\1|;' \
      )                                                                           # The x-coordinate of our encoded binary bit.
      Y_DEST=$( \
        echo -n "${Y_DEST}" | \
        sed 's|^\([.]\{1\}[0-9]\{1,\}\)$|0\1|; s|^\([0-9]\{1,\}\)[.]\{1\}[0-9]\{1,\}$|\1|;' \
      )                                                                           # The y-coordinate of our encoded binary bit.
      
      local SIDE_LEN=$( wc -l /tmp/.hilbert | cut -d ' ' -f 1 )                   # Use the number of lines in our temporary file to extract the side
                                                                                  # -length of the square perimeter that our Hilbert Curve fills.
      local LINE_FROM_FILE="$( \
        sed "$(( $SIDE_LEN - $Y_DEST ))q;d" /tmp/.hilbert \
      )"                                                                          # Copy the line we want to edit from our temporary file.
                                                                                  # NOTE: Just like drawing graphics right-side up, we "draw" from
                                                                                  #       bottom left, up and over to bottom right.
      
      local Q=0; local R=$(( $SIDE_LEN - 1 ));
      # BEGIN: Data mutation block. #   #   # ----------------------------------- #   #   #
        if [ ! -z "${DECODE_DATA}" ]; then
          STATE="${STATE}${LINE_FROM_FILE:$X_DEST:1}"
        else
          if [ $X_DEST -eq $Q ]; then
            # First character of line edge case.
            LINE_FROM_FILE="${DATA:$I:1}${LINE_FROM_FILE:$(( $X_DEST + 1 ))}"
          elif [ $X_DEST -eq $R ]; then
            # Last character of line edge case.
            LINE_FROM_FILE="${LINE_FROM_FILE:0:$X_DEST}${DATA:$I:1}"
          else
            # Default behavior of middle characters.
            LINE_FROM_FILE="${LINE_FROM_FILE:0:$X_DEST}${DATA:$I:1}${LINE_FROM_FILE:$(( $X_DEST + 1 ))}"
          fi
          # Overwrite the original contents of the file at line $Y_DEST.
          sed -i "$(( $SIDE_LEN - $Y_DEST ))s|.*|${LINE_FROM_FILE}|;" /tmp/.hilbert
        fi
      # END: Data mutation block.   #   #   # ----------------------------------- #   #   #
    else                                                                          # Generate four subshells that will interact with the next lower level
                                                                                  # of recursion.
      STATE="${STATE}$( \
        HILBERT_LVL=$(( $DATA_LVL + 1 )); \
        HILBERT_PT0_ANGLE=${INHERITED_ANGLE}; \
        HILBERT_SCALAR=${INHERITED_SCALAR}; \
        HILBERT_X_OFFSET=$( printf '%0.f' "${X_DEST}" ); \
        HILBERT_Y_OFFSET=$( printf '%0.f' "${Y_DEST}" ); \
        hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" $SUBSHELL_FLAGS; \
      )"                                                                          # Capture echoed state from lower levels of recursion.
      
    fi
    I=$(( $I + 1 ))                                                               # Increment to next encoded character or next subshell.
  done

  if [ -z "${HILBERT_LVL}" ]; then                                                # All recursion has been completed and we are back on the root level.
    local TEMP_DATA=
    if [ ! -z "${DECODE_DATA}" ]; then                                            # If we are decoding an encoded string...
      TEMP_DATA=$( echo -n "${STATE}" | tr -d '\n' )                              # ...Capture our recursive state as a single line.
    else                                                                          # If we are encoding into a new Hilbert Curve...
      if [ -f /tmp/.hilbert ]; then                                               # ...And if the temporary file exists...
        TEMP_DATA=$( cat /tmp/.hilbert | tr -d '\n' )                             # ...Capture the contents of our temporary file as a single line.
      fi
    fi
    local OUTPUT_DATA=
    local BYTE_I=0
    local DATUM=
    while [ $BYTE_I -lt ${#TEMP_DATA} ]; do                                       # Iterate across the bytes of binary data in $TEMP_DATA.
      DATUM="$( \
        printf '%02X' "$( \
          echo -n "ibase=2; ${TEMP_DATA:$BYTE_I:8}" | \
          bc -l \
        )"
      )"
      OUTPUT_DATA="${OUTPUT_DATA}\x${DATUM}"                                      # Convert each byte of our binary data into escaped, upper-case
                                                                                  # hexadecimal form UTF-8 character code bytes.
      BYTE_I=$(( $BYTE_I + 8 ))                                                   # Increment to the next byte.
    done
    if [ ! -z "${DECODE_DATA}" ]; then                                            # If we are decoding an encoded string...
      echo -en "${OUTPUT_DATA}" | \
      iconv -f UTF-32LE -t UTF-8 | \
      sed "s|^\(.*\)$( echo -en "\xF4\x8F\xBF\xBF" ).*$|\1|"                      # ...Convert from binary back into characters, then echo all data up
                                                                                  #    until our custom "end of text" character U+10FFFF without a
                                                                                  #    trailing newline character.
    else                                                                          # If we are encoding into a new Hilbert Curve...
      echo -n "${OUTPUT_DATA}" | sed 's|\\x||g'                                   # ...Echo our final hexadecimal string with escape sequences removed
                                                                                  #    and without a trailing newline character.
    fi
  else                                                                            # Not all recursion has been completed and we are not back on the root
                                                                                  # level.
    [ ! -z "${DECODE_DATA}" ] && echo -n "${STATE}"                               # While decoding, echo state from lower levels of recursion so that
                                                                                  # upper levels can capture it.
  fi
}