#!/bin/sh

# Original Author:    Marcin Chwedczuk
# Published Article:  http://blog.marcinchwedczuk.pl/iterative-algorithm-for-drawing-hilbert-curve
# Github:             https://github.com/marcin-chwedczuk/hilbert_curve
#
# sh translation by:  Allen Woods

is_numeric() {
  local EXIT_CODE_1=0
  local DEC_REQUIRED=
  local POS_REQUIRED=
  local ARG=
  for OPT in $@; do
    case $OPT in
      -f|--float)
        DEC_REQUIRED=1
        ;;
      -i|--int)
        DEC_REQUIRED=0
        ;;
      -n|--negative-only)
        POS_REQUIRED=0
        ;;
      -p|--positive-only)
        POS_REQUIRED=1
        ;;
      *)
        ARG=$OPT
        ;;
    esac
  done

  local NUM_TYPE_ERROR=; local NUM_VALUE_ERROR=;

  if [ ! -z "${DEC_REQUIRED}" ]; then
    if [ $DEC_REQUIRED -eq 1 ]; then
      if [ -z "$( echo -n "${ARG}" | grep -o '\.' )" ]; then
        [ -z "${NUM_TYPE_ERROR}" ] && NUM_TYPE_ERROR=1
      fi
    elif [ $DEC_REQUIRED -eq 0 ]; then
      if [ ! -z "$( echo -n "${ARG}" | grep -o '\.' )" ]; then
        [ -z "${NUM_TYPE_ERROR}" ] && NUM_TYPE_ERROR=1
      fi
    fi
  fi

  if [ ! -z "${POS_REQUIRED}" ]; then
    if [ $POS_REQUIRED -eq 0 ]; then
      if [ -z "$( echo -n "${ARG}" | sed 's|^\([-]\{0,1\}\).*$|\1|' )" ]; then
        [ -z "${NUM_VALUE_ERROR}" ] && NUM_VALUE_ERROR=1
      fi
    elif [ $POS_REQUIRED -eq 1 ]; then
      if [ ! -z "$( echo -n "${ARG}" | sed 's|^\([-]\{0,1\}\).*$|\1|' )" ]; then
        [ -z "${NUM_VALUE_ERROR}" ] && NUM_VALUE_ERROR=1
      fi
    fi
  fi

  if [ -z "${NUM_TYPE_ERROR}" ] && [ -z "${NUM_VALUE_ERROR}" ]; then
    echo "${ARG}"
  fi
}

last_2_bits () {
  local ARG=$( is_numeric $1 -i -p )
  if [ ! -z "${ARG}" ]; then
    printf '%02d' "$(( $ARG & 3 ))"
  fi
}

h_index_2_xy () {
  local H_IDX=$( is_numeric $1 -i -p )
  local N_MAX=$( is_numeric $2 -i -p )

  local POSITIONS="00011110"
  local BITS=$( last_2_bits $H_IDX )
  BITS=$(( $BITS * 2 ))
  local TMP=${POSITIONS:$BITS:2}

  H_IDX=$(( $H_IDX >> 2 ))

  local X=${TMP:0:1}
  local Y=${TMP:1:1}

  local N=4
  while [ $N -le $N_MAX ]; do
    local N_2=$(( $N / 2 ))
    case $( last_2_bits $H_IDX ) in
      0)
        TMP=$X; X=$Y; Y=$TMP;
        ;;
      1)
        X=$X
        Y=$(( $Y + $N_2 ))
        ;;
      2)
        X=$(( $X + $N_2 ))
        Y=$(( $Y + $N_2 ))
        ;;
      3)
        TMP=$Y
        Y=$(( ( $N_2 - 1 ) - $X ))
        X=$(( ( $N_2 - 1 ) - $TMP ))
        X=$(( $X + $N_2 ))
        ;;
    esac
    H_IDX=$(( $H_IDX >> 2 ))
    N=$(( $N * 2 ))
  done
  printf '%d %d\n' "${X}" "${Y}"
}

hilbert () {
  local N_MAX=$1
  local N=$( echo "scale=0; sqrt($N_MAX)" | bc -l )
  local I=0
  local CURR=
  while [ $I -lt $N_MAX ]; do
    CURR="$( h_index_2_xy $I $N )"
    printf '%s\n' "${CURR}"
    I=$(( $I + 1 ))
  done
}