#!/bin/sh
encode_data_at_rest () {
  # Require both arguments.
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "ERROR: Please provide data-to-wrap / wrapped-data string and passphrase string as arguments."
    return 1
  fi
  # Original text of argument one (data/wrapper).
  local DATA_WRAP_STR="${1}"
  # Binary-encoded contents of first argument (data/wrapper).
  local DATA_WRAP_BIN="$( \
    echo -n "${DATA_WRAP_STR}" | \
    xxd -b -c 1 | \
    awk '{ print $2 }' | \
    tr -d '\n' \
  )"
  # Binary-encoded length of DATA_WRAP_BIN (64-bit word).
  local DATA_WRAP_LEN_WORD="$( \
    echo -n "obase=2; ${#DATA_WRAP_STR}" | bc | \
    awk \
    '{
      "printf \"%064s\" " $ARGV[1] "| tr \" \" \"0\"" | getline(nl);
      print(nl)
    }' \
  )"
  # Original text of argument two (passphrase).
  local PHRASE_STR="${2}"
  # Binary-encoded contents of second argument (passphrase).
  local PHRASE_BIN="$( \
    echo -n "${PHRASE_STR}" | \
    xxd -b -c 1 | \
    awk '{ print $2 }' | \
    tr -d '\n' \
  )"
  # Binary-encoded length of PHRASE (8-bit word).
  local PHRASE_LEN_WORD="$( \
    echo -n "obase=2; ${#PHRASE_STR}" | bc | \
    awk \
    '{
      "printf \"%08s\" " $ARGV[1] "| tr \" \" \"0\"" | getline(nl);
      print(nl)
    }' \
  )"

  # Scale value for floating point precision.
  local SC=16

  # Placeholder for the final binary word.
  local BINARY_WORD=$( \
    printf "%0$(( ${#DATA_WRAP_LEN_WORD} + ${#PHRASE_LEN_WORD} + ${#DATA_WRAP_BIN} + ${#PHRASE_BIN} ))s" "." | \
    tr " " "." \
  )
  
  local L=
  local N=

  local I=0; local J=0; local K=$(( ${#DATA_WRAP_LEN_WORD} - 1 ));
  # Place bits of data-to-wrap / wrapped-data encoded length into BINARY_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#BINARY_WORD} - 2 ) / $K ) * ${I} ) + 0" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${BINARY_WORD:$N:1}" = '.' ]; then
      if [ $N -eq $J ]; then
        BINARY_WORD="${DATA_WRAP_LEN_WORD:$I:1}${BINARY_WORD:$(( $N + 1 ))}"
      else
        BINARY_WORD="${BINARY_WORD:0:$N}${DATA_WRAP_LEN_WORD:$I:1}${BINARY_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${#PHRASE_LEN_WORD} - 1 ));
  # Place bits of passphrase encoded length into BINARY_WORD. (Reversed)
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#BINARY_WORD} - 2 ) / $K ) * ${I} ) + 1" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${BINARY_WORD:$N:1}" = "." ]; then
      if [ $N -eq $J ]; then
        BINARY_WORD="${PHRASE_LEN_WORD:$(( $K - $I )):1}${BINARY_WORD:$(( $N + 1 ))}"
      elif [ $N -eq $(( ( ${#BINARY_WORD} - 2 ) + 1 )) ]; then
        BINARY_WORD="${BINARY_WORD:0:$N}${PHRASE_LEN_WORD:$(( $K - $I )):1}"
      else
        BINARY_WORD="${BINARY_WORD:0:$N}${PHRASE_LEN_WORD:$(( $K - $I )):1}${BINARY_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  # Placeholder for sensitive data binary word.
  local DATA_WORD=$( \
    printf "%0$(( ${#DATA_WRAP_BIN} + ${#PHRASE_BIN} ))s" "." | \
    tr " " "." | \
    tr -d '\n'
  )

  I=0; J=0; K=$(( ${#DATA_WRAP_BIN} - 1 ));
  # Place bits of data-to-wrap / wrapped-data string into DATA_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#DATA_WORD} - 1 ) / $K ) * ${I} ) + 0" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${DATA_WORD:$N:1}" = "." ]; then
      if [ $N -eq $J ]; then
        DATA_WORD="${DATA_WRAP_BIN:$I:1}${DATA_WORD:$(( $N + 1 ))}"
      elif [ $N -eq $K ]; then
        DATA_WORD="${DATA_WORD:0:$N}${DATA_WRAP_BIN:$I:1}"
      else
        DATA_WORD="${DATA_WORD:0:$N}${DATA_WRAP_BIN:$I:1}${DATA_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${#DATA_WORD} - 1 )); L=$(( ${#PHRASE_BIN} - 1 ));
  # Place bits of passphrase string into DATA_WORD. (Reversed)
  while [[ $I -ge $J && $I -le $K ]]; do
    if [ "${DATA_WORD:$I:1}" = "." ]; then
      if [ $I -eq $J ]; then
        DATA_WORD="${PHRASE_BIN:$L:1}${DATA_WORD:$(( $I + 1 ))}"
        [ $L -gt 0 ] && L=$(( $L - 1 ))
      elif [ $I -eq $K ]; then
        DATA_WORD="${DATA_WORD:0:$I}${PHRASE_BIN:$L:1}"
        [ $L -gt 0 ] && L=$(( $L - 1 ))
      else
        DATA_WORD="${DATA_WORD:0:$I}${PHRASE_BIN:$L:1}${DATA_WORD:$(( $I + 1 ))}"
        [ $L -gt 0 ] && L=$(( $L - 1 ))
      fi
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${#BINARY_WORD} - 1 )); L=0;
  # Merge DATA_WORD with BINARY_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    if [ "${BINARY_WORD:$I:1}" = "." ]; then
      BINARY_WORD="${BINARY_WORD:0:$I}${DATA_WORD:$L:1}${BINARY_WORD:$(( $I + 1 ))}"
      [ $L -lt $(( ${#DATA_WORD} - 1 )) ] && L=$(( $L + 1 ))
    fi
    I=$(( $I + 1 ))
  done

  local BIT_N=0
  local OUTPUT_HEX=
  
  # Convert BINARY_WORD to hex.
  # NOTE: Other means of interpreting the binary will cause mutation of
  #       data based on format and/or locale.
  while [[ $BIT_N -ge 0 && $BIT_N -le $(( ${#BINARY_WORD} - 8 )) ]]; do
    local HEX_BYTE=$( \
      printf '%02X' "$( \
        echo -n "ibase=2; ${BINARY_WORD:$BIT_N:8}" | bc \
      )" \
    )
    OUTPUT_HEX="$( \
      echo -en "${OUTPUT_HEX}${HEX_BYTE}"
    )"
    BIT_N=$(( $BIT_N + 8 ))
  done

  printf '%s\n' "${OUTPUT_HEX}"
}