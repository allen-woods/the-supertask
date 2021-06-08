#!/bin/sh
encode_data_at_rest () (
  # Require both arguments.
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "ERROR: Please provide data-to-wrap / wrapped-data string and passphrase string as arguments."
    return 1
  fi
  # Binary-encoded contents of first argument (data/wrapper).
  DATA_WRAP="$( \
    echo -n "${1}" | \
    xxd -b -c 1 | \
    tr -d '\n' | \
    sed 's|[0-9a-f]\{8\}[:]\{1\}[ ]\{1\}||g; s|[ ]\{2\}[^ ]\{1\}| |g; s|[ ]\{1\}||g;' \
  )"
  # Binary-encoded length of DATA_WRAP (64-bit word).
  DATA_WRAP_LEN="$( \
    echo "obase=2; ${#DATA_WRAP}" | bc | \
    awk \
    '{
      "printf \"%064s\" " $ARGV[1] "| tr \" \" \"0\"" | getline(nl);
      print(nl)
    }' \
  )"
  # Binary-encoded contents of second argument (passphrase).
  PHRASE="$( \
    echo -n "${2}" | \
    xxd -b -c 1 | \
    tr -d '\n' | \
    sed 's|[0-9a-f]\{8\}[:]\{1\}[ ]\{1\}||g; s|[ ]\{2\}[^ ]\{1\}| |g; s|[ ]\{1\}||g;' \
  )"
  # Binary-encoded length of PHRASE (8-bit word).
  PHRASE_LEN="$( \
    echo "obase=2; ${#PHRASE}" | bc | \
    awk \
    '{
      "printf \"%08s\" " $ARGV[1] "| tr \" \" \"0\"" | getline(nl);
      print(nl)
    }' \
  )"

  # Scale value for floating point precision.
  SC=16

  # Placeholder for the final binary word.
  BINARY_WORD=$( \
    printf "%0$(( ${#DATA_WRAP_LEN} + ${#PHRASE_LEN} + ${#DATA_WRAP} + ${#PHRASE} ))s" "." | \
    tr " " "." \
  )
  
  I=0; J=0; K=$(( ${#DATA_WRAP_LEN} - 1 ));
  # Place bits of data-to-wrap / wrapped-data encoded length into BINARY_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#BINARY_WORD} - 2 ) / $K ) * ${I} ) + 0" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${BINARY_WORD:$N:1}" = '.' ]; then
      if [ $N -eq $J ]; then
        BINARY_WORD="${DATA_WRAP_LEN:$I:1}${BINARY_WORD:$(( $N + 1 ))}"
      else
        BINARY_WORD="${BINARY_WORD:0:$N}${DATA_WRAP_LEN:$I:1}${BINARY_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${#PHRASE_LEN} - 1 ));
  # Place bits of passphrase encoded length into BINARY_WORD. (Reversed)
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#BINARY_WORD} - 2 ) / $K ) * ${I} ) + 1" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${BINARY_WORD:$N:1}" = "." ]; then
      if [ $N -eq $J ]; then
        BINARY_WORD="${PHRASE_LEN:$(( $K - $I )):1}${BINARY_WORD:$(( $N + 1 ))}"
      elif [ $N -eq $(( ( ${#BINARY_WORD} - 2 ) + 1 )) ]; then
        BINARY_WORD="${BINARY_WORD:0:$N}${PHRASE_LEN:$(( $K - $I )):1}"
      else
        BINARY_WORD="${BINARY_WORD:0:$N}${PHRASE_LEN:$(( $K - $I )):1}${BINARY_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  # Placeholder for sensitive data binary word.
  DATA_WORD=$( \
    printf "%0$(( ${#DATA_WRAP} + ${#PHRASE} ))s" "." | \
    tr " " "." \
  )

  I=0; J=0; K=$(( ${#DATA_WRAP} - 1 ));
  # Place bits of data-to-wrap / wrapped-data string into DATA_WORD.
  while [[ $I -ge $J && $I -le $K ]]; do
    N=$( echo -n "scale=${SC}; ( ( ( ${#DATA_WORD} - 1 ) / $K ) * ${I} ) + 0" | bc )
    N=$( printf '%.0f' "${N}" )
    if [ "${DATA_WORD:$N:1}" = "." ]; then
      if [ $N -eq $J ]; then
        DATA_WORD="${DATA_WRAP:$I:1}${DATA_WORD:$(( $N + 1 ))}"
      elif [ $N -eq $K ]; then
        DATA_WORD="${DATA_WORD:0:$N}${DATA_WRAP:$I:1}"
      else
        DATA_WORD="${DATA_WORD:0:$N}${DATA_WRAP:$I:1}${DATA_WORD:$(( $N + 1 ))}"
      fi
    fi
    I=$(( $I + 1 ))
  done

  I=0; J=0; K=$(( ${#DATA_WORD} - 1 )); L=$(( ${#PHRASE} - 1 ));
  # Place bits of passphrase string into DATA_WORD. (Reversed)
  while [[ $I -ge $J && $I -le $K ]]; do
    if [ "${DATA_WORD:$I:1}" = "." ]; then
      if [ $I -eq $J ]; then
        DATA_WORD="${PHRASE:$L:1}${DATA_WORD:$(( $I + 1 ))}"
        [ $L -gt 0 ] && L=$(( $L - 1 ))
      elif [ $I -eq $K ]; then
        DATA_WORD="${DATA_WORD:0:$I}${PHRASE:$L:1}"
        [ $L -gt 0 ] && L=$(( $L - 1 ))
      else
        DATA_WORD="${DATA_WORD:0:$I}${PHRASE:$L:1}${DATA_WORD:$(( $I + 1 ))}"
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

  BIT_N=0

  # Convert BINARY_WORD to octal.
  # NOTE: Without this step, the presence of a pattern in the data could be easily identified.
  while [[ $BIT_N -ge 0 && $BIT_N -le $(( ${#BINARY_WORD} - 8 )) ]]; do
    CHAR_NUM=$( echo -n "ibase=2; obase=8; ${BINARY_WORD:$BIT_N:8}" | bc )
    [ -z "${OCTAL_WORD}" ] && \
    OCTAL_WORD="$( echo -en "\\${CHAR_NUM}" )" || \
    OCTAL_WORD="${OCTAL_WORD}$( echo -en "\\${CHAR_NUM}" )"
    BIT_N=$(( $BIT_N + 8 ))
  done

  # Convert OCTAL_WORD to base64.
  B64_STRING="$( echo -n $OCTAL_WORD | base64 | tr -d ' ' )"

  # Convert B64_STRING to hex.
  OUTPUT_HEX="$( echo -n $B64_STRING | hexdump -ve '/1 "%02X"' )"

  printf '%s\n' "${OUTPUT_HEX}"
)