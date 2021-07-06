#!/bin/sh
# Work in progress, recursive implementation of Hilbert Curve.
hilbert () {
  if [ -z "${1}" ]; then
    echo "\033[1;37m\033[41m ERROR: \033[0m Missing argument: quoted data string."
    return 1
  else
    local DATA="${1}"
    local DATA_LEN=${#DATA}
    
    # Define HILBERT_LVL inside subshell where recursion is called.
    local DATA_LVL=${HILBERT_LVL:-1}

    local n=0
    local SIZE=$(( 4 ** $n ))
    until [ $SIZE -ge $DATA_LEN ]; do
      n=$(( $n + 1 ))
      SIZE=$(( 4 ** $n ))
    done
    local SC=11
    local CENTER=$( echo "sqrt(${SIZE}) / 2" | bc -l )
    local RADIUS=$( echo "scale=${SC}; ${CENTER} * sqrt(2)" | bc -l )
    # Here we need to calculate rotations based on $DATA_LVL.
    # If we are on a level beyond 1, we must also check HILBERT_NODE.
    case $(( $DATA_LVL % 2 )) in
      0)
        # rotate from normal
        ;;
      1)
        # default behavior
        ;;
    esac
  fi
}