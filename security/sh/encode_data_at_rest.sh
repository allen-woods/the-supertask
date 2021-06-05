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
  echo "wrap: ${DATA_WRAP}, ${#DATA_WRAP};"
  
  # Binary-encoded length of DATA_WRAP (64-bit word).
  DATA_WRAP_LEN="$( \
    echo "obase=2; ${#DATA_WRAP}" | bc | \
    awk \
    '{
      "printf \"%064s\" " $ARGV[1] "| tr \" \" \"0\"" | getline(nl);
      print(nl)
    }' \
  )"
  echo "wrap len: ${DATA_WRAP_LEN}, ${#DATA_WRAP_LEN};"

  # Binary-encoded contents of second argument (passphrase).
  PHRASE="$( \
    echo -n "${2}" | \
    xxd -b -c 1 | \
    tr -d '\n' | \
    sed 's|[0-9a-f]\{8\}[:]\{1\}[ ]\{1\}||g; s|[ ]\{2\}[^ ]\{1\}| |g; s|[ ]\{1\}||g;' \
  )"
  echo "phrase: ${PHRASE}, ${#PHRASE};"

  # Binary-encoded length of PHRASE (8-bit word).
  PHRASE_LEN="$( \
    echo "obase=2; ${#PHRASE}" | bc | \
    awk \
    '{
      "printf \"%08s\" " $ARGV[1] "| tr \" \" \"0\"" | getline(nl);
      print(nl)
    }' \
  )"
  echo "phrase len: ${PHRASE_LEN}, ${#PHRASE_LEN}."

  # Scale value for floating point precision.
  SC=16

  # Placeholder for the final binary word.
  BINARY_WORD=$( \
    printf "%0$(( ${#DATA_WRAP_LEN} + ${#PHRASE_LEN} + ${#DATA_WRAP} + ${#PHRASE} ))s" "." | \
    tr " " "." \
  )
  echo "init word: ${BINARY_WORD}"
  echo "init len: ${#BINARY_WORD}"

  # Initialize variables that drive incrementation.
  # Assign values required by A.
  BIT_N=0; DOT_COUNT=0; WRITE_COUNT=0

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
      # If this is the first dot to write, then write it without incrementing dot_count.
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
          echo "init diff: ${DIFF_A}"
        fi
      else
        RATIO_A=$(
          echo -n "scale=${SC}; ${DOT_COUNT} / ${DIFF_A}" | \
          bc | \
          sed 's|^\([0-9]\{0,\}\)\.[0-9]\{1,\}$|\1|g' \
        )
        if [ ! -z "${RATIO_A}" ] && [ $RATIO_A -eq 1 ]; then
          if [ $BIT_N -eq $LEN_A1 ]; then
            BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP_LEN:$WRITE_COUNT:1}"
          else
            BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP_LEN:$WRITE_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
          fi
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
            echo "diff: ${DIFF_A}"
          fi
          DOT_COUNT=0
        else
          DOT_COUNT=$(( $DOT_COUNT + 1 ))
        fi
      fi
    fi
    # Increment bit position.
    BIT_N=$(( $BIT_N + 1 ))
  done

  # # Assign values required by B.
  # BIT_N=$(( ${#BINARY_WORD} - 1 )); DOT_COUNT=0;

  # # Processing of 8-bit word PHRASE_LEN.
  # LEN_B1=$(( ${#PHRASE_LEN} + ${#DATA_WRAP} + ${#PHRASE} - 1 ))
  # LEN_B2=$(( ${#PHRASE_LEN} - 1 ))
  # FLOAT_B=$( echo -n "scale=${SC}; ${LEN_B1} / ${LEN_B2}" | bc )
  # MULT_B=0
  # INT_B=
  # while [[ $BIT_N -ge 0 && $BIT_N -le $(( ${#BINARY_WORD} - 1 )) ]]; do
  #   # We have detected an empty bit in BINARY_WORD.
  #   if [ "${BINARY_WORD:$BIT_N:1}" = "." ]; then
  #     # Does the sum of empty bits found so far correspond to a mapped bit in BINARY_WORD?
  #     # (y=mx+b formula)
  #     INT_B=$( \
  #       echo -n "scale=${SC}; ${MULT_B} * ${FLOAT_B}" | \
  #       bc | \
  #       sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
  #     )
  #     # Does this empty bit correspond to a mapped location in DATA_WRAP_LEN?
  #     # CALC_DOT=$(
  #     #   echo -n "scale=${SC}; ${DOT_COUNT} % ${INT_B}" | bc \
  #     # )
  #     # Yes: the empty bit is mapped!
  #     # if [ $CALC_DOT -eq 0 ]; then # x-coordinate of y=mx+b formula satisfied.
  #       # Yes: the sum of empty bits is mapped!
  #       if [ $DOT_COUNT -eq $INT_B ]; then # y-coordinate of y=mx+b formula satisfied.
  #         # Insert middle bit, preserve adjacent data.
  #         BINARY_WORD="${BINARY_WORD:0:$BIT_N}${PHRASE_LEN:$DOT_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
  #         # Increment multiplier.
  #         MULT_B=$(( $MULT_B + 1 ))
  #       fi
  #     # fi
  #     # Increment number of dots counted.
  #     DOT_COUNT=$(( $DOT_COUNT + 1 ))
  #   fi
  #   # Dencrement bit position.
  #   BIT_N=$(( $BIT_N - 1 ))
  # done

  # echo "B word: ${BINARY_WORD}"
  # echo "B len: ${#BINARY_WORD}"

  # # Assign values required by C.
  # BIT_N=0; DOT_COUNT=0;

  # # Processing of "I" bits-long word DATA_WRAP.
  # LEN_C1=$(( ${#DATA_WRAP} + ${#PHRASE} - 1 ))
  # LEN_C2=$(( ${#DATA_WRAP} - 1 ))
  # FLOAT_C=$( echo -n "scale=${SC}; ${LEN_C1} / ${LEN_C2}" | bc )
  # MULT_C=0
  # INT_C=
  # while [[ $BIT_N -ge 0 && $BIT_N -le $(( ${#BINARY_WORD} - 1 )) ]]; do
  #   # We have detected an empty bit in BINARY_WORD.
  #   if [ "${BINARY_WORD:$BIT_N:1}" = "." ]; then
  #     # Does the sum of empty bits found so far correspond to a mapped bit in BINARY_WORD?
  #     # (y=mx+b formula)
  #     INT_C=$( \
  #       echo -n "scale=${SC}; ${MULT_C} * ${FLOAT_C}" | \
  #       bc | \
  #       sed 's|^\([0-9]\{1,\}\)\.[0-9]\{1,\}$|\1|g' \
  #     )
  #     # # Does this empty bit correspond to a mapped location in DATA_WRAP_LEN?
  #     # CALC_DOT=$(
  #     #   echo -n "scale=${SC}; ${DOT_COUNT} % ${INT_C}" | bc \
  #     # )
  #     # Yes: the empty bit is mapped!
  #     # if [ $CALC_DOT -eq 0 ]; then # x-coordinate of y=mx+b formula satisfied.
  #       # Yes: the sum of empty bits is mapped!
  #       if [ $DOT_COUNT -eq $INT_C ]; then # y-coordinate of y=mx+b formula satisfied.
  #         # Insert middle bit, preserve adjacent data.
  #         BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP:$DOT_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
  #         # Increment multiplier.
  #         MULT_C=$(( $MULT_C + 1 ))
  #       fi
  #     # fi
  #     # Increment number of dots counted.
  #     DOT_COUNT=$(( $DOT_COUNT + 1 ))
  #   fi
  #   # Increment bit position.
  #   BIT_N=$(( $BIT_N + 1 ))
  # done

  # echo "C word: ${BINARY_WORD}"
  # echo "C len: ${#BINARY_WORD}"

  # # Assign values required by D.
  # BIT_N=$(( ${#BINARY_WORD} - 1 )); DOT_COUNT=0;

  # # Processing of "J" bits-long word PHRASE.
  # while [[ $BIT_N -ge 0 && $BIT_N -le $(( ${#BINARY_WORD} - 1 )) ]]; do
  #   # We have detected an empty bit in BINARY_WORD.
  #   if [ "${BINARY_WORD:$BIT_N:1}" = "." ]; then
  #     # Insert middle bit, preserve adjacent data.
  #     BINARY_WORD="${BINARY_WORD:0:$BIT_N}${DATA_WRAP:$DOT_COUNT:1}${BINARY_WORD:$(( $BIT_N + 1 ))}"
  #     # Increment number of dots counted.
  #     DOT_COUNT=$(( $DOT_COUNT + 1 ))
  #   fi
  #   # Decrement bit position.
  #   BIT_N=$(( $BIT_N - 1 ))
  # done

  # echo "final word: ${BINARY_WORD}"
  # echo "final len: ${#BINARY_WORD}"

  BIT_N=0

  # Convert BINARY_WORD to octal.
  while [[ $BIT_N -ge 0 && $BIT_N -lt $(( ${#BINARY_WORD} - 8 )) ]]; do
    CHAR_NUM=$( echo -n "ibase=2; obase=8; ${BINARY_WORD:$BIT_N:8}" | bc )
    [ -z "${OCTAL_WORD}" ] && \
    OCTAL_WORD=$( echo -en "\\${CHAR_NUM}" ) || \
    OCTAL_WORD="${OCTAL_WORD}$( echo -en "\\${CHAR_NUM}" )"
    BIT_N=$(( $BIT_N + 8 ))
  done

  # Convert OCTAL_WORD to base64.
  B64_STRING=$( echo -n $OCTAL_WORD | base64 | tr -d ' ' )

  # Convert B64_STRING to hex.
  OUTPUT_HEX=$( echo -n $B64_STRING | hexdump -ve '/1 "%02X"' )

  printf '%s' "${BINARY_WORD}" # "${OUTPUT_HEX}"
)