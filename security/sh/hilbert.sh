#!/bin/sh
# Work in progress, recursive implementation of Hilbert Curve.
hilbert () {
  # Handle errors.
  if [ -z "${1}" ]; then
    echo "\033[1;37m\033[41m ERROR: \033[0m Missing argument: quoted data string."
    return 1
  fi
  # Parse command-line argument.
  local DATA="${1}"
  local DATA_LEN=${#DATA}
  # Set precision of floating point values.
  local SC=11
  # Define constant(s).
  local PI_CONST=3.141592653589793
  local RAD_CONST=$( echo "scale=${SC}; ${PI_CONST} / 180" | bc -l )
  local ROOT_2=$( echo "scale=${SC}; sqrt(2)" | bc -l )
  local HALF_ROOT_2=$( echo "scale=${SC}; ${ROOT_2} / 2" | bc -l )
  # Subshell environment variables.
  local DATA_LVL=${HILBERT_LVL:-0}                  # Track recursive depth within each subshell.
  local REL_ANGLE=${HILBERT_REL_ANGLE:-0}           # Relative angle from which all other angles are measured.
  local PT0_ANGLE=${HILBERT_PT0_ANGLE:-225}         # Starting angle for plotting points.
  local ANGLE_STEP=90                               # Angle of incrementation from point to point.
  local ANGLE_STEP_SCALAR=${HILBERT_SCALAR:-( -1 )} # Scalar value for 90-degree step value (determines cw or ccw rotation).
  # Calculate nearest Hilbert Curve size that can contain $DATA.
  local n=0
  local SIZE=$(( 4 ** $n ))
  until [ $SIZE -ge $DATA_LEN ]; do
    n=$(( $n + 1 ))
    SIZE=$(( 4 ** $n ))
  done
  # Trigonometric variables for plotting points.
  local HALF_SIZE=$( echo "scale=${SC}; sqrt(${SIZE}) / 2" | bc -l )
  local CENTER_X=$( echo "scale=${SC}; ${HILBERT_OFFSET_X:-$HALF_SIZE}" | bc -l )
  local CENTER_Y=$( echo "scale=${SC}; ${HILBERT_OFFSET_Y:-$HALF_SIZE}" | bc -l )
  local RADIUS=$( echo "scale=${SC}; ( ${HALF_SIZE} / 2 ) * ${ROOT_2}" | bc -l )
  local LVL_REMAINDER=$(( $DATA_LVL % 2 ))
  for I in 0 1 2 3; do
    case $LVL_REMAINDER in
      0)
        if [ $I -eq 0 ]; then
          if [ $RADIUS -eq $HALF_ROOT_2 ]; then
            # mutate data in this location.
          else
            # generate sub-node
            # set rel angle to -90
            # set scalar to +1
          fi
        elif [ $I -eq 3 ]; then
        if [ $RADIUS -eq $HALF_ROOT_2 ]; then
            # mutate data in this location.
          else
            # generate sub-node
            # set rel angle to +90
            # set scalar to +1
          fi
        else
          if [ $RADIUS -eq $HALF_ROOT_2 ]; then
            # mutate data in this location.
          else
            # generate sub-node
            # set rel angle to current level's rel angle
            # set scalar to -1
          fi
        fi
        ;;
      1)
        if [ $I -eq 0 ]; then
          if [ $RADIUS -eq $HALF_ROOT_2 ]; then
            # mutate data in this location.
          else
            # generate sub-node
            # set rel angle to +90
            # set scalar to -1
          fi
        elif [ $I -eq 3 ]; then
          if [ $RADIUS -eq $HALF_ROOT_2 ]; then
            # mutate data in this location.
          else
            # generate sub-node
            # set rel angle to -90
            # set scalar to -1
          fi
        else
          if [ $RADIUS -eq $HALF_ROOT_2 ]; then
            # mutate data in this location.
          else
            # generate sub-node
            # set rel angle to current level's rel angle
            # set scalar to +1
          fi
        fi
        ;;
    esac
  done

  # For reference:
  # for I in 0 1 2 3; do
  #   # Calculate x-coordinate and take the integer part (floor function).
  #   POINT_X=$( printf '%0.f' \
  #     "$( \
  #       echo "scale=${SC}; \
  #       CENTER_X + \
  #       c( \
  #         ( \
  #           ${ANGLE_START} + \
  #           ( \
  #             ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} \
  #           ) \
  #         ) * \
  #         ( \
  #           ${RAD_CONST} \
  #         ) \
  #       ) * \
  #       ${RADIUS}" | \
  #       bc -l \
  #     )" \
  #   )

  #   # Calculate y-coordinate and take the integer part (floor function).
  #   POINT_Y=$( printf '%0.f' \
  #     "$( \
  #       echo "scale=${SC}; \
  #       CENTER_Y + \
  #       s( \
  #         ( \
  #           ${ANGLE_START} + \
  #           ( \
  #             ${I} * ${ANGLE_STEP_SCALAR} * ${ANGLE_STEP} \
  #           ) \
  #         ) * \
  #         ( \
  #           ${RAD_CONST} \
  #         ) \
  #       ) * \
  #       ${RADIUS}" | \
  #       bc -l \
  #     )" \
  #   )
  # done
}