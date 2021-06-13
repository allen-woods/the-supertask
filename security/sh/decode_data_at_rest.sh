#!/bin/sh
decode_data_at_rest () (
  # Require the argument.
  if [ -z "${1}" ]; then
    echo "ERROR: Please provide encoded-data-at-rest string as argument."
    return 1
  fi
  # Original text of argument one (hexadecimal format of binary word).
  BINARY_HEX_STR="${1}"
  # Parse the data into its binary form.
  CHAR_N=0
  BINARY_WORD=
  while [[ $CHAR_N -ge 0 && $CHAR_N -le $(( ${#BINARY_HEX_STR} - 2 )) ]]; do
    BINARY_BYTE=$( \
      printf '%08d' "$( \
        echo -n "ibase=16; obase=2; ${BINARY_HEX_STR:$CHAR_N:2}" | bc \
      )" \
    )
    BINARY_WORD="${BINARY_WORD}${BINARY_BYTE}"
    CHAR_N=$(( $CHAR_N + 2 ))
  done

  # Binary-decoded data/wrapper (of unknown length "I" bits).
  DATA_WRAP_BIN=
  # UTF-8 contents of DATA_WRAP.
  DATA_WRAP_STR=
  # Expected number of bits (64) required to encode length of DATA_WRAP.
  DATA_WRAP_WORD_LEN=64
  # Actual length of DATA_WRAP decoded from BINARY_WORD.
  DATA_WRAP_NUM_BITS=
  # Binary-decoded passphrase (of unknown length "J" bits).
  PHRASE_BIN=
  # UTF-8 contents of PHRASE.
  PHRASE_STR=
  # Expected number of bits (8) required to encode length of PHRASE.
  PHRASE_WORD_LEN=8
  # Actual length of PHRASE decoded from BINARY_WORD.
  PHRASE_NUM_BITS=

  # Scale value for floating point precision.
  SC=16

  I=0; J=0; K=$(( ${DATA_WRAP_WORD_LEN} - 1 ));
  # Decode bits of data-to-wrap / wrapped-data encoded length from BINARY_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#BINARY_WORD} - 2 ) / $K ) * ${I} ) + 0" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${BINARY_WORD:$N:1}" != "." ] && [ ! -z "${BINARY_WORD:$N:1}" ]; then
      DATA_WRAP_NUM_BITS="${DATA_WRAP_NUM_BITS}${BINARY_WORD:$N:1}"
      if [ $N -eq $J ]; then
        BINARY_WORD=".${BINARY_WORD:$(( $N + 1 ))}"
      else
        BINARY_WORD="${BINARY_WORD:0:$N}.${BINARY_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${PHRASE_WORD_LEN} - 1 ));
  # Decode bits of passphrase encoded length from BINARY_WORD. (Reversed)
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#BINARY_WORD} - 2 ) / $K ) * ${I} ) + 1" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${BINARY_WORD:$N:1}" != "." ] && [ ! -z "${BINARY_WORD:$N:1}" ]; then
      PHRASE_NUM_BITS="${BINARY_WORD:$N:1}${PHRASE_NUM_BITS}"
      if [ $N -eq $J ]; then
        BINARY_WORD=".${BINARY_WORD:$(( $N + 1 ))}"
      elif [ $N -eq $(( ( ${#BINARY_WORD} - 2 ) + 1 )) ]; then
        BINARY_WORD="${BINARY_WORD:0:$N}."
      else
        BINARY_WORD="${BINARY_WORD:0:$N}.${BINARY_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  DATA_WRAP_NUM_BITS=$( echo -n "ibase=2; ${DATA_WRAP_NUM_BITS}" | bc )
  DATA_WRAP_NUM_BITS=$(( ${DATA_WRAP_NUM_BITS} * 8 ))

  PHRASE_NUM_BITS=$( echo -n "ibase=2; ${PHRASE_NUM_BITS}" | bc )
  PHRASE_NUM_BITS=$(( ${PHRASE_NUM_BITS} * 8 ))

  # Placeholder for sensitive data binary word.
  DATA_WORD=

  I=2; J=2; K=$(( ${#BINARY_WORD} - 3 ));
  # Decode DATA_WORD from BINARY_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    if [ "${BINARY_WORD:$I:1}" != "." ] && [ ! -z "${BINARY_WORD:$I:1}" ]; then
      DATA_WORD="${DATA_WORD}${BINARY_WORD:$I:1}"
      BINARY_WORD="${BINARY_WORD:0:$I}.${BINARY_WORD:$(( $I + 1 ))}"
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${DATA_WRAP_NUM_BITS} - 1 ));
  #echo "k=${K}"
  # Decode bits of data-to-wrap / wrapped-data string from DATA_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#DATA_WORD} - 1 ) / $K ) * ${I} ) + 0" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${DATA_WORD:$N:1}" != "." ] && [ ! -z "${DATA_WORD:$N:1}" ]; then
      DATA_WRAP_BIN="${DATA_WRAP_BIN}${DATA_WORD:$N:1}"
      if [ $N -eq $J ]; then
        DATA_WORD=".${DATA_WORD:$(( $N + 1 ))}"
      elif [ $N -eq $K ]; then
        DATA_WORD="${DATA_WORD:0:$N}."
      else
        DATA_WORD="${DATA_WORD:0:$N}.${DATA_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${#DATA_WORD} - 1 ));
  # Decode bits of passphrase string from DATA_WORD. (Reversed)
  while [[ $I -ge $J && $I -le $K ]]; do
    if [ "${DATA_WORD:$I:1}" != "." ] && [ ! -z "${DATA_WORD:$I:1}" ]; then
      PHRASE_BIN="${DATA_WORD:$I:1}${PHRASE_BIN}"
      if [ $I -eq $J ]; then
        DATA_WORD=".${DATA_WORD:$(( $I + 1 ))}"
      elif [ $I -eq $K ]; then
        DATA_WORD="${DATA_WORD:0:$I}."
      else
        DATA_WORD="${DATA_WORD:0:$I}.${DATA_WORD:$(( $I + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  CHAR_N=0

  # Convert DATA_WRAP to UTF-8.
  while [[ $CHAR_N -ge 0 && $CHAR_N -le $(( ${DATA_WRAP_NUM_BITS} - 8 )) ]]; do
    CHAR_NUM=$( echo -n "ibase=2; obase=8; ${DATA_WRAP_BIN:$CHAR_N:8}" | bc )
    [ -z "${DATA_WRAP_STR}" ] && \
    DATA_WRAP_STR="$( echo -en "\\$( printf '%03d' "${CHAR_NUM}" )" )" || \
    DATA_WRAP_STR="${DATA_WRAP_STR}$( echo -en "\\$( printf '%03d' "${CHAR_NUM}" )" )"
    CHAR_N=$(( $CHAR_N + 8 ))
  done

  CHAR_N=0

  # Convert PHRASE to UTF-8.
  while [[ $CHAR_N -ge 0 && $CHAR_N -le $(( ${PHRASE_NUM_BITS} - 8 )) ]]; do
    CHAR_NUM=$( echo -n "ibase=2; obase=8; ${PHRASE_BIN:$CHAR_N:8}" | bc )
    [ -z "${PHRASE_STR}" ] && \
    PHRASE_STR="$( echo -en "\\$( printf '%03d' "${CHAR_NUM}" )" )" || \
    PHRASE_STR="${PHRASE_STR}$( echo -en "\\$( printf '%03d' "${CHAR_NUM}" )" )"
    CHAR_N=$(( $CHAR_N + 8 ))
  done

  printf '%s\n' "${DATA_WRAP_STR} ${PHRASE_STR}"
)