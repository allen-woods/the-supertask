#!/bin/sh
# Recursive implementation of Hilbert Curve.
hilbert () {
  # Handle errors.
  if [ -z "${1}" ]; then
    echo -e "\033[1;37m\033[41m ERROR: \033[0m Missing argument: quoted data string."
    return 1
  fi
  # Parse command-line argument.
  local DATA="${1}"
  local DATA_LEN=${#DATA}
  local FOURTH_DATA_LEN=$(( $DATA_LEN / 4 ))

  # Set precision of floating point values.
  local SC=11

  # Define constant(s).
  local PI_CONST=3.141592653589793
  local RAD_CONST=$( echo "scale=${SC}; ${PI_CONST} / 180" | bc -l )
  local ROOT_2=$( echo "scale=${SC}; sqrt(2)" | bc -l )
  local HALF_ROOT_2=$( echo "scale=${SC}; ${ROOT_2} / 2" | bc -l )

  # Subshell environment variables.
  local DATA_LVL=${HILBERT_LVL:-0}                    # Track recursive depth within each subshell.
  local REL_ANGLE=${HILBERT_REL_ANGLE:-0}             # Relative angle from which all other angles are measured.
  local PT0_ANGLE=${HILBERT_PT0_ANGLE:-225}           # Starting angle for plotting points.
  local ANGLE_STEP=90                                 # Angle of incrementation from point to point.
  local ANGLE_STEP_SCALAR=${HILBERT_SCALAR:-( -1 )}   # Scalar value for 90-degree step value (determines cw or ccw rotation).

  # Calculate nearest Hilbert Curve size that can contain $DATA.
  local n=0
  local SIZE=$(( 4 ** $n ))
  until [ $SIZE -ge $DATA_LEN ]; do
    n=$(( $n + 1 ))
    SIZE=$(( 4 ** $n ))
  done

  # Trigonometric variables for plotting points.
  local ROOT_N=$( echo "scale=${SC}; sqrt(${SIZE})" | bc -l )
  local HALF_SIZE=$( echo "scale=${SC}; ${ROOT_N} / 2" | bc -l )
  local CENTER_X=$( echo "scale=${SC}; ${HILBERT_X_OFFSET:-$HALF_SIZE}" | bc -l )
  local CENTER_Y=$( echo "scale=${SC}; ${HILBERT_Y_OFFSET:-$HALF_SIZE}" | bc -l )
  local RADIUS=$( echo "scale=${SC}; ( ${HALF_SIZE} / 2 ) * ${ROOT_2}" | bc -l )

  # Create the destination file.
  if [ $DATA_LVL -eq 0 ] && [ ! -f /tmp/.hilbert ]; then
    local LINE=1
    while [ $LINE -le $ROOT_N ]; do
      printf "%0${ROOT_N}s\n" " " >> /tmp/.hilbert
      LINE=$(( $LINE + 1 ))
    done
  fi

  # Parse whether layer is even or odd.
  local LVL_REMAINDER=$(( $DATA_LVL % 2 ))
  for I in 0 1 2 3; do
    # If this recursive depth points to character indexes and line
    # numbers, then perform data mutation.
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
  done

  # Spit out the file contents as a single line.
  if [ $DATA_LVL -eq 0 ] && [ -f /tmp/.hilbert ]; then
    cat /tmp/.hilbert | tr -d '\n'
  fi
}