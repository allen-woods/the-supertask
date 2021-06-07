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

  # Initialize variables that drive incrementation.
  # Assign values required by A.
  BIT_N=0; DOT_COUNT=0; WRITE_COUNT=0;

  # Processing of 64-bit word DATA_WRAP_LEN.
  LEN_A1=$(( ${#BINARY_WORD} - 1 ))
  LEN_A2=$(( ${#DATA_WRAP_LEN} - 1 ))
  FLOAT_A=$( echo -n "scale=${SC}; ${LEN_A1} / ${LEN_A2}" | bc )
  MULT_A=0
  LAST_A=
  THIS_A=
  DIFF_A=
  while [[ $BIT_N -ge 0 && $BIT_N -le $LEN_A1 ]]; do
    # We have detected an empty bit in BINARY_WORD.
    if [ "${BINARY_WORD:$BIT_N:1}" = "." ]; then
      # This is the first dot, write it without incrementing DOT_COUNT.
      if [ $WRITE_COUNT -eq 0 ]; then
        BINARY_WORD="${DATA_WRAP_LEN:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
        WRITE_COUNT=$(( $WRITE_COUNT + 1 ))
        MULT_A=$(( $MULT_A + 1 ))
        LAST_A=-1
        THIS_A=$( \
          echo -n "scale=${SC}; ${MULT_A} * ${FLOAT_A}" | \
          bc | \
          sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
        )
        if [ ! -z "${LAST_A}" ] && [ ! -z "${THIS_A}" ]; then
          DIFF_A=$(( $THIS_A - $LAST_A - 1 ))
        fi
      else
        if [ $BIT_N -eq $LEN_A1 ]; then
          BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP_LEN:$WRITE_COUNT:1}"
        else
          if [ $DOT_COUNT -eq $DIFF_A ]; then
            BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP_LEN:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
            WRITE_COUNT=$(( $WRITE_COUNT + 1 ))
            MULT_A=$(( $MULT_A + 1 ))
            LAST_A=$THIS_A
            THIS_A=$( \
              echo -n "scale=${SC}; ${MULT_A} * ${FLOAT_A}" | \
              bc | \
              sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
            )
            if [ ! -z "${LAST_A}" ] && [ ! -z "${THIS_A}" ]; then
              DIFF_A=$(( $THIS_A - $LAST_A - 1))
            fi
            DOT_COUNT=0
          else
            DOT_COUNT=$(( $DOT_COUNT + 1 ))
          fi
        fi
      fi
    fi
    # Increment bit position.
    BIT_N=$(( $BIT_N + 1 ))
  done

  # Assign values required by B.
  BIT_N=$(( ${#BINARY_WORD} - 2 )); DOT_COUNT=0; WRITE_COUNT=0;

  # Processing of 8-bit word PHRASE_LEN.
  LEN_B1=$(( ${#PHRASE_LEN} + ${#DATA_WRAP} + ${#PHRASE} - 1 ))
  LEN_B2=$(( ${#PHRASE_LEN} - 1 ))
  FLOAT_B=$( echo -n "scale=${SC}; ${LEN_B1} / ${LEN_B2}" | bc )
  MULT_B=0
  LAST_B=
  THIS_B=
  DIFF_B=
  while [[ $BIT_N -ge 1 && $BIT_N -le $(( ${#BINARY_WORD} - 2 )) ]]; do
    # We have detected an empty bit in BINARY_WORD.
    if [ "${BINARY_WORD:$BIT_N:1}" = "." ]; then
      # This is the first dot, write it without incrementing DOT_COUNT.
      if [ $WRITE_COUNT -eq 0 ]; then
        BINARY_WORD="${BINARY_WORD:0:$BIT_N}${PHRASE_LEN:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
        WRITE_COUNT=$(( $WRITE_COUNT + 1 ))
        MULT_B=$(( $MULT_B + 1 ))
        LAST_B=-1
        THIS_B=$( \
          echo -n "scale=${SC}; ${MULT_B} * ${FLOAT_B}" | \
          bc | \
          sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
        )
        if [ ! -z "${LAST_B}" ] && [ ! -z "${THIS_B}" ]; then
          DIFF_B=$(( $THIS_B - $LAST_B - 1 ))
        fi
      else
        if [ $BIT_N -eq 1 ]; then
          BINARY_WORD="${BINARY_WORD:0:$BIT_N}${PHRASE_LEN:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
        else
          if [ $DOT_COUNT -eq $DIFF_B ]; then
            BINARY_WORD="${BINARY_WORD:0:$BIT_N}${PHRASE_LEN:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
            WRITE_COUNT=$(( $WRITE_COUNT + 1 ))
            MULT_B=$(( $MULT_B + 1 ))
            LAST_B=$THIS_B
            THIS_B=$( \
              echo -n "scale=${SC}; ${MULT_B} * ${FLOAT_B}" | \
              bc | \
              sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
            )
            if [ ! -z "${LAST_B}" ] && [ ! -z "${THIS_B}" ]; then
              DIFF_B=$(( $THIS_B - $LAST_B - 1 ))
            fi
            DOT_COUNT=0
          else
            DOT_COUNT=$(( $DOT_COUNT + 1 ))
          fi
        fi
      fi
    fi
    # Increment bit position.
    BIT_N=$(( $BIT_N - 1 ))
  done

  # Assign values required by C.
  BIT_N=2; DOT_COUNT=0; WRITE_COUNT=0

  # Processing of "I" bits-long word DATA_WRAP.
  LEN_C1=$(( ${#DATA_WRAP} + ${#PHRASE} - 1 ))
  LEN_C2=$(( ${#DATA_WRAP} - 1 ))
  FLOAT_C=$( echo -n "scale=${SC}; ${LEN_C1} / ${LEN_C2}" | bc )
  MULT_C=0
  LAST_C=
  THIS_C=
  DIFF_C=
  while [[ $BIT_N -ge 2 && $BIT_N -le $(( ${#BINARY_WORD} - 3 )) ]]; do
    # We have detected an empty bit in BINARY_WORD.
    if [ "${BINARY_WORD:$BIT_N:1}" = "." ]; then
      # This is the first dot, write it without incrementing DOT_COUNT.
      if [ $WRITE_COUNT -eq 0 ]; then
        BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
        WRITE_COUNT=$(( $WRITE_COUNT + 1 ))
        MULT_C=$(( $MULT_C + 1 ))
        LAST_C=-1
        THIS_C=$( \
          echo -n "scale=${SC}; ${MULT_C} * ${FLOAT_C}" | \
          bc | \
          sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
        )
        if [ ! -z "${LAST_C}" ] && [ ! -z "${THIS_C}" ]; then
          DIFF_C=$(( $THIS_C - $LAST_C - 1 ))
        fi
      else
        if [ $BIT_N -eq $(( ${#BINARY_WORD} -3 )) ]; then
          BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
        else
          if [ $DOT_COUNT -eq $DIFF_C ]; then
            BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
            WRITE_COUNT=$(( $WRITE_COUNT + 1 ))
            MULT_C=$(( $MULT_C + 1 ))
            LAST_C=$THIS_C
            THIS_C=$( \
              echo -n "scale=${SC}; ${MULT_C} * ${FLOAT_C}" | \
              bc | \
              sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
            )
            if [ ! -z "${LAST_C}" ] && [ ! -z "${THIS_C}" ]; then
              DIFF_C=$(( $THIS_C - $LAST_C - 1 ))
            fi
            DOT_COUNT=0
          else
            DOT_COUNT=$(( $DOT_COUNT + 1 ))
          fi
        fi
      fi
    fi
    # Increment bit position.
    BIT_N=$(( $BIT_N + 1 ))
  done
  
  # Assign values required by D.
  BIT_N=$(( ${#BINARY_WORD} - 4 )); WRITE_COUNT=0;

  # Processing of "J" bits-long word PHRASE.
  while [[ $BIT_N -ge 3 && $BIT_N -le $(( ${#BINARY_WORD} - 4 )) ]]; do
    # We have detected an empty bit in BINARY_WORD.
    if [ "${BINARY_WORD:$BIT_N:1}" = "." ]; then
      # Insert middle bit, presenrve adjacent data.
      BINARY_WORD="${BINARY_WORD:0:$BIT_N}${PHRASE:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
      # Increment number of writes.
      WRITE_COUNT=$(( $WRITE_COUNT + 1 ))
    fi
    # Decrement bit position.
    BIT_N=$(( $BIT_N - 1 ))
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