#!/bin/sh
# Recursive implementation of Hilbert Curve.
# Obfuscates plain text at the binary level.
hilbert () {
  #
  # HANDLE FATAL EXCEPTIONS # ------------------------------- #
  #
  if [ -z "${1}" ]; then
    echo -e "\033[1;37m\033[41m ERROR: \033[0m Missing argument: quoted data string."
    return 1
  else
    if [ ! -z "${2}" ]; then
      if [ "${2}" != "-d" ]; then
        echo -e "\033[1;37m\033[41m ERROR! \033[0m\nExpected option: -d to decode string.\nReceived: ${2}."
        return 1
      else
        local DECODE_DATA=1
        local STATE=
      fi
    fi
  fi
  #
  # LOCAL VARIABLES # --------------------------------------- #
  #
  local DATA=
  if [ ! -z "${HILBERT_LVL}" ]; then                                              # If we detect we are on a lower level of recursion...
    DATA="${1}"                                                                   # ...Receive data to be obfuscated as-is.
  else                                                                            # Otherwise, if the incoming data is not in binary format...
    DATA=$( echo -en "${1}" | xxd -b -c 1 | awk '{ print $2 }' | tr -d '\n' )     # ...Convert data to be obfuscated to binary format.
  fi
  local DATA_LEN=${#DATA}                                                         # Capture the length of incoming data.
  
  local SC=11                                                                     # Set global floating point precision of decimals.
  
  local PI_CONST=3.141592653589793                                                # Approximation of Pi.
  local RAD_CONST=$( echo "scale=${SC}; ${PI_CONST} / 180" | bc -l )              # Conversion from degree to radian.
  local ROOT_2=$( echo "scale=${SC}; sqrt(2)" | bc -l )                           # Square root of 2.
  local HALF_ROOT_2=$( echo "scale=${SC}; ${ROOT_2} / 2" | bc -l )                # Square root of 2, divided by 2.

  local DATA_LVL=${HILBERT_LVL:-0}                                                # Track recursive depth within each subshell. 
  local PT0_ANGLE=${HILBERT_PT0_ANGLE:-"-135"}                                    # Parent subshell's starting angle for plotting points.
  local ANGLE_STEP=90                                                             # Angle of incrementation from point to point.
  local ANGLE_STEP_SCALAR=${HILBERT_SCALAR:-1}                                    # Scalar value of +/-1 (determines cw or ccw rotation).
  
  #
  # DYNAMIC RESIZING # -------------------------------------- #
  #
  local n=0                                                                       # Nth power that 4 is raised to.
  local SIZE=                                                                     # Result of (4 ** n); size of Hilbert Curve.
  while [ -z "${SIZE}" ] || [ $SIZE -lt $DATA_LEN ]; do                           # Calculate nearest Hilbert Curve that can contain $DATA.
    SIZE=$(( 4 ** $n ))
    n=$(( $n + 1 ))
  done

  if [ $DATA_LVL -eq 0 ]; then                                                    # If and only if we are on the root level of recursion...
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
          )"                                                                        # ...Generate a string of random characters whose length is equal
                                                                                    #    to $FOLD_VALUE and whose bits will be used to fill the rest of
                                                                                    #    the Hilbert Curve.
          DATA="${DATA}${PADDING_BIN}"                                              # Append our padding character(s).
          DATA_LEN=${#DATA}                                                         # Re-measure length of our padded data.
        fi
      else                                                                          # If we have not detected a multiple of 8 bits...
        local PADDING_BIN="$( \
          tr -cd [0-1] < /dev/random | \
          fold -w ${DIFF} | \
          head -n 1 | \
          tr -d '\n' \
        )"                                                                          # ...Generate a random string of bits to fill the rest of the
                                                                                    #    Hilbert Curve.
        DATA="${DATA}${PADDING_BIN}"                                                # Append our padding character(s).
        DATA_LEN=${#DATA}                                                           # Re-measure length of our padded data.
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
  
  if [ $DATA_LVL -eq 0 ]; then
    [ -f /tmp/.hilbert ] && rm -f /tmp/.hilbert                                   # Create the destination file (erase existing if found).
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

  local LVL_REMAINDER=$(( $DATA_LVL % 2 ))                                        # Parse the current level of recursive depth.
  
  case $LVL_REMAINDER in
    0)
      local SIGN_180=1                                                            # This level is EVEN.
      ;;
    1)
      local SIGN_180=-1                                                           # This level is ODD.
      ;;
  esac

  local DRAW_ANGLE=
  local DRAW_SCALAR=$(( -1 * $ANGLE_STEP_SCALAR ))
  
  local I=0; local J=0; local K=3;                                                # Iterate over points of origin / characters.
  while [[ $I -ge $J && $I -le $K ]]; do                                          # Calculate angles.
    if [ $I -eq $J ]; then                                                        # First point.
      local INHERITED_ANGLE=$(( -1 * ( $PT0_ANGLE - 90 ) ))
      local INHERITED_SCALAR=$DRAW_SCALAR
    elif [ $I -eq $K ]; then                                                      # Last point.
      local INHERITED_ANGLE=$(( -1 * ( ( $PT0_ANGLE - 90 ) + ( $SIGN_180 * 180 ) ) ))
      local INHERITED_SCALAR=$DRAW_SCALAR
    elif [[ $I -gt $J && $I -lt $K ]]; then                                       # Middle points (default).
      local INHERITED_ANGLE=$PT0_ANGLE
      local INHERITED_SCALAR=$ANGLE_STEP_SCALAR
    fi

    # This angle is used to position points of origin for lower
    # levels of recursion, or to position encoded characters.
    DRAW_ANGLE=$(( ( -1 * ( $PT0_ANGLE - 90 ) ) + ( $I * $DRAW_SCALAR * $ANGLE_STEP ) ))
    
    local X_DEST=$( \
      echo "scale=${SC}; \
      ${CENTER_X} + \
      c( \
        ${DRAW_ANGLE} * \
        ${RAD_CONST} \
      ) * ${RADIUS}" | \
      bc -l \
    )                                                                             # Solve for x-coordinate as a floating point value.
    
    local Y_DEST=$( \
      echo "scale=${SC}; \
      ${CENTER_Y} + \
      s( \
        ${DRAW_ANGLE} * \
        ${RAD_CONST} \
      ) * ${RADIUS}" | \
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
        HILBERT_PT0_ANGLE=$INHERITED_ANGLE; \
        HILBERT_SCALAR=$INHERITED_SCALAR; \
        HILBERT_X_OFFSET=$( printf '%0.f' "${X_DEST}" ); \
        HILBERT_Y_OFFSET=$( printf '%0.f' "${Y_DEST}" ); \
        hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" "${2}"; \
      )"                                                                          # Capture echoed state from lower levels of recursion.
      
    fi
    I=$(( $I + 1 ))                                                               # Increment to next encoded character or next subshell.
  done

  if [ $DATA_LVL -eq 0 ]; then                                                    # All recursion has been completed and we are back on the root level.
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
    while [ $BYTE_I -lt ${#TEMP_DATA} ]; do                                       # Iterate across the bytes of binary data in $TEMP_DATA.
      OUTPUT_DATA="${OUTPUT_DATA}$( \
        printf '%02X' "$( \
          echo -n "ibase=2; ${TEMP_DATA:$BYTE_I:8}" | bc -l \
        )" \
      )"                                                                          # Convert each byte of our binary data into upper-case hexadecimal.

      BYTE_I=$(( $BYTE_I + 8 ))                                                   # Increment to the next byte.
    done
    if [ ! -z "${DECODE_DATA}" ]; then                                            # If we are decoding an encoded string...
      echo -n "${OUTPUT_DATA}" | \
      xxd -r -ps | \
      sed "s|^\(.*\)$( echo -en "\xF4\x8F\xBF\xBF" ).*$|\1|"                      # ...Convert our output back into string format, then echo all data
                                                                                  #    up until our custom "end of text" character U+10FFFF without a 
                                                                                  #    trailing newline character.
    else                                                                          # If we are encoding into a new Hilbert Curve...
      echo -n "${OUTPUT_DATA}"                                                    # ...Echo our final hexadecimal string without a trailing newline
                                                                                  #    character.  
    fi
  else                                                                            # Not all recursion has been completed and we are not back on the root
                                                                                  # level.
    [ ! -z "${DECODE_DATA}" ] && echo -n "${STATE}" | tr -d '\n'                  # While decoding, echo state from lower levels of recursion so that
                                                                                  # upper levels can capture it.
  fi
}