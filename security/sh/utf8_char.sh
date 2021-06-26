#!/bin/sh
utf8_char() {
  local INT_NUM=$( \
    echo -n $1 | tr '[:lower:]' '[:upper:]' | \
    awk \
    '{
      idx = match($ARGV[1], /^[\\]{0,1}[Uu]{1}[+]{0,1}/)
      if (idx == 0) {
        is_dec = match($ARGV[1], /^[0-9]{1,7}$/)
        if (is_dec != 0) {
          "echo -n " $ARGV[1] | getline(nl);
          print(nl)
        }
      } else {
        is_hex = match($ARGV[1], /^[\\]{0,1}[uU]{1}[+]{0,1}[0-9a-fA-F]{2,6}$/)
        if (is_hex != 0) {
          "echo -n \"ibase=16;" $ARGV[1] "\" | \
          tr -d /[\\][uU][+]/ | \
          bc" | getline(nl);
          print(nl)
        }
      }
    }' \
  )
  # Fail silently if argument fails to be parsed.
  [ -z "${INT_NUM}" ] && echo "" && return 0

  # Numbers > 524287 return "invalid" in printf,
  # so we conditionally use strings.
  local NUM_INVALID="$( \
    ( \
      printf '%021d' $( echo -en "obase=2; ${INT_NUM}" ) \
    ) 2>&1 | grep -o "invalid" \
  )"
  local BIN_WORD=
  if [ ! -z "${NUM_INVALID}" ]; then
    BIN_WORD="$( \
      echo -n "obase=2; ${INT_NUM}" | bc | \
      awk \
      '{
        "printf \"%021s\" " $ARGV[1] "| tr \" \" \"0\"" | getline(nl);
        print(nl)
      }' \
    )"
  else
    BIN_WORD="$( \
      echo -n "obase=2; ${INT_NUM}" | bc | \
      awk \
      '{
        "printf \"%021d\" " $ARGV[1] | getline(nl);
        print(nl)
      }' \
    )"
  fi

  local OUTPUT_CHAR=

  if [ $INT_NUM -ge 33 ] && [ $INT_NUM -lt 128 ]; then
    BYTE_1=$( echo -en "ibase=2; obase=8; 0${BIN_WORD:14:7}" | bc )
    # Characters 00000 - 0007F
    OUTPUT_CHAR=$( echo -en "\\${BYTE_1}" )
  elif [ $INT_NUM -ge 128 ] && [ $INT_NUM -lt 2048 ]; then
    BYTE_1=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:15:6}" | bc )
    BYTE_2=$( echo -n "ibase=2; obase=8; 110${BIN_WORD:10:5}" | bc )
    # Characters 00080 - 007FF
    OUTPUT_CHAR=$( echo -en "\\${BYTE_2}\\${BYTE_1}" )
  elif [ $INT_NUM -ge 2048 ] && [ $INT_NUM -lt 65536 ]; then
    BYTE_1=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:15:6}" | bc )
    BYTE_2=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:9:6}" | bc )
    BYTE_3=$( echo -n "ibase=2; obase=8; 1110${BIN_WORD:5:4}" | bc )
    # Characters 00800 - 0FFFF
    OUTPUT_CHAR=$( echo -en "\\${BYTE_3}\\${BYTE_2}\\${BYTE_1}" )
  elif [ $INT_NUM -ge 65536 ] && [ $INT_NUM -le 1114111 ]; then
    BYTE_1=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:15:6}" | bc )
    BYTE_2=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:9:6}" | bc )
    BYTE_3=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:3:6}" | bc )
    BYTE_4=$( echo -n "ibase=2; obase=8; 11110${BIN_WORD:0:3}" | bc )
    # Characters 10000 - 3134F
    OUTPUT_CHAR=$( echo -en "\\${BYTE_4}\\${BYTE_3}\\${BYTE_2}\\${BYTE_1}" )
  fi

  case "${OUTPUT_CHAR}" in
    [^[:print:]])
      # Fail silently with control characters (return empty string).
      echo -n "" && return 0
      ;;
    [[:print:]])
      echo -en "${OUTPUT_CHAR}"
      ;;
  esac
}