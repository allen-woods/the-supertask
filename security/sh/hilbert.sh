#!/bin/sh
# Recursive implementation of Hilbert Curve.
hilbert () {
  # Handle errors.
  if [ -z "${1}" ]; then
    echo -e "\033[1;37m\033[41m ERROR: \033[0m Missing argument: quoted data string."
    return 1
  fi
  echo -e "\033[1;36m Passed argument. \033[0m" # DEBUG

  # Parse command-line argument.
  local DATA="${1}"
  echo -e "\033[1;36m DATA=${DATA} \033[0m" # DEBUG
  local DATA_LEN=${#DATA}
  echo -e "\033[1;36m DATA_LEN=${DATA_LEN} \033[0m" # DEBUG
  local FOURTH_DATA_LEN=$(( $DATA_LEN / 4 ))
  echo -e "\033[1;36m FOURTH_DATA_LEN=${FOURTH_DATA_LEN} \033[0m" # DEBUG

  # Set precision of floating point values.
  local SC=11
  echo -e "\033[1;36m SC=${SC} \033[0m" # DEBUG

  # Define constant(s).
  local PI_CONST=3.141592653589793
  echo -e "\033[1;36m PI_CONST=${PI_CONST} \033[0m" # DEBUG
  local RAD_CONST=$( echo "scale=${SC}; ${PI_CONST} / 180" | bc -l )
  echo -e "\033[1;36m RAD_CONST=${RAD_CONST} \033[0m" # DEBUG
  local ROOT_2=$( echo "scale=${SC}; sqrt(2)" | bc -l )
  echo -e "\033[1;36m ROOT_2=${ROOT_2} \033[0m" # DEBUG
  local HALF_ROOT_2=$( echo "scale=${SC}; ${ROOT_2} / 2" | bc -l )
  echo -e "\033[1;36m HALF_ROOT_2=${HALF_ROOT_2} \033[0m" # DEBUG

  # Subshell environment variables.
  local DATA_LVL=${HILBERT_LVL:-0}                    # Track recursive depth within each subshell.
  echo -e "\033[1;36m DATA_LVL=${DATA_LVL} \033[0m" # DEBUG
  local REL_ANGLE=${HILBERT_REL_ANGLE:-0}             # Relative angle from which all other angles are measured.
  echo -e "\033[1;36m REL_ANGLE=${REL_ANGLE} \033[0m" # DEBUG
  local PT0_ANGLE=${HILBERT_PT0_ANGLE:-225}           # Starting angle for plotting points.
  echo -e "\033[1;36m PT0_ANGLE=${PT0_ANGLE} \033[0m" # DEBUG
  local ANGLE_STEP=90                                 # Angle of incrementation from point to point.
  echo -e "\033[1;36m ANGLE_STEP=${ANGLE_STEP} \033[0m" # DEBUG
  local ANGLE_STEP_SCALAR=${HILBERT_SCALAR:-( -1 )}   # Scalar value for 90-degree step value (determines cw or ccw rotation).
  echo -e "\033[1;36m ANGLE_STEP_SCALAR=${ANGLE_STEP_SCALAR} \033[0m" # DEBUG

  # Calculate nearest Hilbert Curve size that can contain $DATA.
  local n=0
  local SIZE=$(( 4 ** $n ))
  until [ $SIZE -ge $DATA_LEN ]; do
    n=$(( $n + 1 ))
    SIZE=$(( 4 ** $n ))
  done
  echo -e "\033[1;36m n=${n} \033[0m" # DEBUG
  echo -e "\033[1;36m SIZE=${SIZE} \033[0m" # DEBUG

  # Trigonometric variables for plotting points.
  local ROOT_N=$( echo "scale=${SC}; sqrt(${SIZE})" | bc -l )
  echo -e "\033[1;36m ROOT_N=${ROOT_N} \033[0m" # DEBUG
  local HALF_SIZE=$( echo "scale=${SC}; ${ROOT_N} / 2" | bc -l )
  echo -e "\033[1;36m HALF_SIZE=${HALF_SIZE} \033[0m" # DEBUG
  local CENTER_X=$( echo "scale=${SC}; ${HILBERT_X_OFFSET:-$HALF_SIZE}" | bc -l )
  echo -e "\033[1;36m CENTER_X=${CENTER_X} \033[0m" # DEBUG
  local CENTER_Y=$( echo "scale=${SC}; ${HILBERT_Y_OFFSET:-$HALF_SIZE}" | bc -l )
  echo -e "\033[1;36m CENTER_Y=${CENTER_Y} \033[0m" # DEBUG
  local RADIUS=$( echo "scale=${SC}; ( ${HALF_SIZE} / 2 ) * ${ROOT_2}" | bc -l )
  echo -e "\033[1;36m RADIUS=${RADIUS} \033[0m" # DEBUG

  # Create the destination file.
  if [ $DATA_LVL -eq 0 ] && [ ! -f /tmp/.hilbert ]; then
    local LINE=1
    local LINE_MAX="$( echo -n "${ROOT_N}" | sed 's|^\([0-9]\{1,\}\)[.]\{1\}.*$|\1|' )"
    echo -e "\033[1;36m LINE=${LINE} \033[0m" # DEBUG
    while [ $LINE -le $LINE_MAX ]; do
      printf "%0${ROOT_N}s\n" " " >> /tmp/.hilbert
      echo -e "\033[1;36m Attempted write to file: /tmp/.hilbert \033[0m" # DEBUG
      LINE=$(( $LINE + 1 ))
    done
  fi

  # Parse whether layer is even or odd.
  local LVL_REMAINDER=$(( $DATA_LVL % 2 ))
  echo -e "\033[1;36m LVL_REMAINDER=${LVL_REMAINDER} \033[0m" # DEBUG
  local I=0; local J=0; local K=3;
  while [[ $I -ge $J && $I -le $K ]]; do
    echo -e "\033[1;36m I=${I} \033[0m" # DEBUG
    # If this recursive depth points to character indexes and line
    # numbers, then perform data mutation.

    # NOTE: This conditional block of data mutation needs to be refactored to prevent halt of loop. # DEBUG
    
    if [ "${RADIUS}" = "${HALF_ROOT_2}" ]; then
      # Calculate character index along x-axis.
      local X_DEST=$( \
        printf '%0.f' \
        "$( \
          echo "scale=${SC}; \
          ${CENTER_X} + \
          c( \
            ( \
              ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
              ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
            ) * ${RAD_CONST} \
          ) * ${RADIUS}" | \
          bc -l \
        )" \
      )
      echo -e "\033[1;36m X_DEST=${X_DEST} \033[0m" # DEBUG

      # Calculate line number along y-axis.
      local Y_DEST=$( \
        printf '%0.f' \
        "$( \
          echo "scale=${SC}; \
          ${CENTER_X} + \
          c( \
            ( \
              ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
              ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
            ) * ${RAD_CONST} \
          ) * ${RADIUS}" | \
          bc -l \
        )" \
      )
      echo -e "\033[1;36m Y_DEST=${Y_DEST} \033[0m" # DEBUG

      # Extract the number of points on a given side of the
      # full size plot of the Hilbert Curve.
      local SIDE_LEN=$( wc -l /tmp/.hilbert )

      # Copy the line we want to edit.
      local LINE_FROM_FILE=$( sed "$(( $Y_DEST + 1 ))q;d" )

      # BEGIN: Data mutation block. #   #   #

        if [ $X_DEST -eq 0 ]; then
          # First character of line edge case.
          LINE_FROM_FILE="${DATA:$I:1}${LINE_FROM_FILE:$(( $X_DEST + 1 ))}"
        elif [ $X_DEST -eq $(( $SIDE_LEN - 1 )) ]; then
          # Last character of line edge case.
          LINE_FROM_FILE="${LINE_FROM_FILE:0:$(( $SIDE_LEN - 1 ))}${DATA:$I:1}"
        else
          # Default behavior of middle characters.
          LINE_FROM_FILE="${LINE_FROM_FILE:0:$X_DEST}${DATA:$I:1}${LINE_FROM_FILE:$(( $X_DEST + 1 ))}"
        fi
        # Overwrite the original contents of the file at line ( $Y_DEST + 1 ).
        sed -i "$(( $Y_DEST + 1 ))s|.*|${LINE_FROM_FILE}|" /tmp/.hilbert

        # Return zero to iterate across the next branch once
        # all leaf values have been written.
        [ $I -eq $K ] && return 0

      # END: Data mutation block.   #   #   #
    else
      case $LVL_REMAINDER in
        0) # Even levels (includes 0).
          if [ $I -eq 0 ]; then
            ( \
              HILBERT_LVL=$(( $DATA_LVL + 1 )) \
              HILBERT_REL_ANGLE=$(( $REL_ANGLE - 90 )) \
              HILBERT_PT0_ANGLE=-45 \
              HILBERT_SCALAR=1 \
              HILBERT_X_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_X} + \
                  c( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              HILBERT_Y_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_Y} + \
                  s( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" \
            )
          elif [ $I -eq 3 ]; then
            ( \
              HILBERT_LVL=$(( $DATA_LVL + 1 )) \
              HILBERT_REL_ANGLE=$(( $REL_ANGLE + 90 )) \
              HILBERT_PT0_ANGLE=-45 \
              HILBERT_SCALAR=1 \
              HILBERT_X_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_X} + \
                  c( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              HILBERT_Y_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_Y} + \
                  s( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" \
            )
          else
            ( \
              HILBERT_LVL=$(( $DATA_LVL + 1 )) \
              HILBERT_REL_ANGLE=$REL_ANGLE \
              HILBERT_PT0_ANGLE=$PT0_ANGLE \
              HILBERT_SCALAR=-1 \
              HILBERT_X_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_X} + \
                  c( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              HILBERT_Y_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_Y} + \
                  s( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" \
            )
          fi
          ;;
        1) # Odd levels.
          if [ $I -eq 0 ]; then
              ( \
                HILBERT_LVL=$(( $DATA_LVL + 1 )) \
                HILBERT_REL_ANGLE=$(( $REL_ANGLE + 90 )) \
                HILBERT_PT0_ANGLE=-45 \
                HILBERT_SCALAR=-1 \
                HILBERT_X_OFFSET=$( \
                  printf '%0.f' \
                  "$( \
                    echo "scale=${SC}; \
                    ${CENTER_X} + \
                    c( \
                      ( \
                        ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                        ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                      ) * ${RAD_CONST} \
                    ) * ${RADIUS}" | \
                    bc -l \
                  )" \
                ) \
                HILBERT_Y_OFFSET=$( \
                  printf '%0.f' \
                  "$( \
                    echo "scale=${SC}; \
                    ${CENTER_Y} + \
                    s( \
                      ( \
                        ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                        ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                      ) * ${RAD_CONST} \
                    ) * ${RADIUS}" | \
                    bc -l \
                  )" \
                ) \
                hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" \
              )
          elif [ $I -eq 3 ]; then
              ( \
                HILBERT_LVL=$(( $DATA_LVL + 1 )) \
                HILBERT_REL_ANGLE=$(( $REL_ANGLE - 90 )) \
                HILBERT_PT0_ANGLE=-45 \
                HILBERT_SCALAR=-1 \
                HILBERT_X_OFFSET=$( \
                  printf '%0.f' \
                  "$( \
                    echo "scale=${SC}; \
                    ${CENTER_X} + \
                    c( \
                      ( \
                        ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                        ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                      ) * ${RAD_CONST} \
                    ) * ${RADIUS}" | \
                    bc -l \
                  )" \
                ) \
                HILBERT_Y_OFFSET=$( \
                  printf '%0.f' \
                  "$( \
                    echo "scale=${SC}; \
                    ${CENTER_Y} + \
                    s( \
                      ( \
                        ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                        ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                      ) * ${RAD_CONST} \
                    ) * ${RADIUS}" | \
                    bc -l \
                  )" \
                ) \
                hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" \
              )
          else
            ( \
              HILBERT_LVL=$(( $DATA_LVL + 1 )) \
              HILBERT_REL_ANGLE=$REL_ANGLE \
              HILBERT_PT0_ANGLE=$PT0_ANGLE \
              HILBERT_SCALAR=1 \
              HILBERT_X_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_X} + \
                  c( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              HILBERT_Y_OFFSET=$( \
                printf '%0.f' \
                "$( \
                  echo "scale=${SC}; \
                  ${CENTER_Y} + \
                  s( \
                    ( \
                      ( ${REL_ANGLE} + ${PT0_ANGLE} ) + \
                      ( ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} ) \
                    ) * ${RAD_CONST} \
                  ) * ${RADIUS}" | \
                  bc -l \
                )" \
              ) \
              hilbert "${DATA:$(( $I * $FOURTH_DATA_LEN )):$FOURTH_DATA_LEN}" \
            )
          fi
          ;;
      esac
    fi
    I=$(( $I + 1 ))
    echo -e "\033[1;36m Incremented I to ${I} \033[0m"
  done

  echo -e "\033[1;36m Finished while loop. \033[0m"

  # Spit out the file contents as a single line.
  if [ $DATA_LVL -eq 0 ] && [ -f /tmp/.hilbert ]; then
    cat /tmp/.hilbert | tr -d '\n'
  fi
}