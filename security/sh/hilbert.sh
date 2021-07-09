#!/bin/sh
# Recursive implementation of Hilbert Curve.
hilbert () {
  # Handle errors.
  if [ -z "${1}" ]; then
    echo -e "\033[1;37m\033[41m ERROR: \033[0m Missing argument: quoted data string."
    return 1
  fi

  # Parse and sanitize command-line argument.
  local DATA="$( echo -e "${1}" | sed 's|[\$"`]\{1,\}|\\&|g' )"
  local DATA_LEN=${#DATA}

  # Set precision of floating point values.
  local SC=11

  # Define constant(s).
  local PI_CONST=3.141592653589793
  local RAD_CONST=$( echo "scale=${SC}; ${PI_CONST} / 180" | bc -l )
  local ROOT_2=$( echo "scale=${SC}; sqrt(2)" | bc -l )
  local HALF_ROOT_2=$( echo "scale=${SC}; ${ROOT_2} / 2" | bc -l )

  # Subshell environment variables.
  local DATA_LVL=${HILBERT_LVL:-0}                    # Track recursive depth within each subshell.
  local PT0_ANGLE=${HILBERT_PT0_ANGLE:-"-135"}        # Parent subshell's starting angle for plotting points.
  local ANGLE_STEP=90                                 # Angle of incrementation from point to point.
  local ANGLE_STEP_SCALAR=${HILBERT_SCALAR:-1}        # Scalar value for 90-degree step value (determines cw or ccw rotation).

  # Calculate nearest Hilbert Curve size that can contain $DATA.
  local n=0
  local SIZE=
  while [ -z "${SIZE}" ] || [ $SIZE -lt $DATA_LEN ]; do
    SIZE=$(( 4 ** $n ))
    n=$(( $n + 1 ))
  done

  if [ $SIZE -gt $DATA_LEN ]; then
    # Pad the end of our data to completely fill the curve using
    # trailing "End of Transmission" control characters.
    local PADDING="$( \
      printf "%0$(( $SIZE - $DATA_LEN ))s" ' ' | \
      sed 's| |'"$( echo -e "\x04" )"'|g' \
    )"
    DATA="${DATA}${PADDING}"
    DATA_LEN=${#DATA}
  fi

  local FOURTH_DATA_LEN=$(( $DATA_LEN / 4 ))
  
  # Trigonometric variables for plotting points.
  local ROOT_N=$( echo "scale=${SC}; sqrt(${SIZE})" | bc -l )
  local HALF_SIZE=$( echo "scale=${SC}; ${ROOT_N} / 2" | bc -l )
  local CENTER_X=$( echo "scale=${SC}; ${HILBERT_X_OFFSET:-$HALF_SIZE}" | bc -l )
  local CENTER_Y=$( echo "scale=${SC}; ${HILBERT_Y_OFFSET:-$HALF_SIZE}" | bc -l )
  local RADIUS=$( echo "scale=${SC}; ( ${HALF_SIZE} / 2 ) * ${ROOT_2}" | bc -l )

  # Create the destination file (erase existing if found).
  if [ $DATA_LVL -eq 0 ]; then
    [ -f /tmp/.hilbert ] && rm -f /tmp/.hilbert
    local LINE=1
    local LINE_MAX="$( echo -n "${ROOT_N}" | sed 's|^\([0-9]\{1,\}\)[.]\{1\}.*$|\1|' )"
    while [ $LINE -le $LINE_MAX ]; do
      printf "%0${ROOT_N}s\n" " " >> /tmp/.hilbert
      LINE=$(( $LINE + 1 ))
    done
  fi

  # Parse the current level of recursive depth.
  local LVL_REMAINDER=$(( $DATA_LVL % 2 ))
  case $LVL_REMAINDER in
    0)
      # Even levels.
      local SIGN_180=1
      ;;
    1)
      # Odd levels.
      local SIGN_180=-1
      ;;
  esac

  local DRAW_ANGLE=
  local DRAW_SCALAR=$(( -1 * $ANGLE_STEP_SCALAR ))

  # Iterate over points / characters.
  local I=0; local J=0; local K=3;
  while [[ $I -ge $J && $I -le $K ]]; do
    # Calculate angle.
    if [ $I -eq $J ]; then
      # First point.
      local INHERITED_ANGLE=$(( -1 * ( $PT0_ANGLE - 90 ) ))
      local INHERITED_SCALAR=$DRAW_SCALAR
    elif [ $I -eq $K ]; then
      # Last point.
      local INHERITED_ANGLE=$(( -1 * ( ( $PT0_ANGLE - 90 ) + ( $SIGN_180 * 180 ) ) ))
      local INHERITED_SCALAR=$DRAW_SCALAR
    elif [[ $I -gt $J && $I -lt $K ]]; then
      # Middle points.
      local INHERITED_ANGLE=$PT0_ANGLE
      local INHERITED_SCALAR=$ANGLE_STEP_SCALAR
    fi

    DRAW_ANGLE=$(( ( -1 * ( $PT0_ANGLE - 90 ) ) + ( $I * $DRAW_SCALAR * $ANGLE_STEP ) ))

    # Solve location as a floating point value.
    local X_DEST=$( \
      echo "scale=${SC}; \
      ${CENTER_X} + \
      c( \
        ${DRAW_ANGLE} * \
        ${RAD_CONST} \
      ) * ${RADIUS}" | \
      bc -l \
    )
    local Y_DEST=$( \
      echo "scale=${SC}; \
      ${CENTER_Y} + \
      s( \
        ${DRAW_ANGLE} * \
        ${RAD_CONST} \
      ) * ${RADIUS}" | \
      bc -l \
    )

    # Generate point (subshell) or character.
    if [ "${RADIUS}" = "${HALF_ROOT_2}" ]; then
      # Do not attempt to place "End of Transmission" control characters
      # into final output file.
      #
      # This allows for organic looking data without a strict requirement
      # of strings that are ( 4 ** n ) in length.
      if [ "${DATA:$I:1}" != "$( echo -e "\x04" )" ]; then
        #   #   #
        # NOTE: #
        #   #   #
        #
        # There is a major 'gotcha' when using $( printf '%0.f' "${FLOAT}" ) to remove decimals.
        #
        # Namely, it rounds the trailing decimals to the nearest integer before returning a value!
        # To prevent rounding, prepend zeroes where needed, then retain the leading integer value.
        #
        # Sed is used here, but other methods are possible.

        X_DEST=$( echo "${X_DEST}" | sed 's|^\([.]\{1\}[0-9]\{1,\}\)$|0\1|; s|^\([0-9]\{1,\}\)[.]\{1\}[0-9]\{1,\}$|\1|;' )
        Y_DEST=$( echo "${Y_DEST}" | sed 's|^\([.]\{1\}[0-9]\{1,\}\)$|0\1|; s|^\([0-9]\{1,\}\)[.]\{1\}[0-9]\{1,\}$|\1|;' )

        # Extract the number of points on a given side of the
        # full size plot of the Hilbert Curve.
        local SIDE_LEN=$( wc -l /tmp/.hilbert | cut -d ' ' -f 1 )

        echo -e "\033[1;35m char (${X_DEST}, $(( ${SIDE_LEN} - ${Y_DEST} ))) \033[0m"

        # Copy the line we want to edit.
        # NOTE: Just like in graphics, we need to write our points from the bottom upward.
        local LINE_FROM_FILE="$( sed "$(( $SIDE_LEN - $Y_DEST ))q;d" /tmp/.hilbert )"

        local Q=0; local R=$(( $SIDE_LEN - 1 )); # $(( ${#LINE_FROM_FILE} - 1 ));
        # BEGIN: Data mutation block. #   #   #
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
        # END: Data mutation block.   #   #   #

        # Overwrite the original contents of the file at line $Y_DEST.
        sed -i "$(( $SIDE_LEN - $Y_DEST ))s|.*|${LINE_FROM_FILE}|" /tmp/.hilbert
      fi
    else

      # Generate subshell.
      ( \
        HILBERT_LVL=$(( $DATA_LVL + 1 )); \
        HILBERT_PT0_ANGLE=$INHERITED_ANGLE; \
        HILBERT_SCALAR=$INHERITED_SCALAR; \
        HILBERT_X_OFFSET=$( printf '%0.f' "${X_DEST}" ); \
        HILBERT_Y_OFFSET=$( printf '%0.f' "${Y_DEST}" ); \
        hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}"; \
      )
    fi

    I=$(( $I + 1 ))
  done

  # Spit out the file contents as a single line.
  if [ $DATA_LVL -eq 0 ] && [ -f /tmp/.hilbert ]; then
    cat /tmp/.hilbert # | tr -d '\n'
  fi
}