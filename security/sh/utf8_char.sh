utf8_char() (
  INT_NUM=$( \
    echo -n $1 | \
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

  BIN_WORD=$( \
    echo -n "obase=2; ${INT_NUM}" | bc | \
    awk \
    '{
      "printf \"%021d\" " $ARGV[1] | getline(nl);
      print(nl)
    }' \
  )

  OUTPUT_CHR=

  if [ $INT_NUM -ge 33 ] && [ $INT_NUM -lt 128 ]; then
    BYTE_1=$( echo -en "ibase=2; obase=8; 0${BIN_WORD:14:7}" | bc )
    
    # Characters 00000 - 0007F
    OUTPUT_CHR=$( echo -en "\\${BYTE_1}" )

  elif [ $INT_NUM -ge 128 ] && [ $INT_NUM -lt 2048 ]; then
    BYTE_1=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:15:6}" | bc )
    BYTE_2=$( echo -n "ibase=2; obase=8; 110${BIN_WORD:10:5}" | bc )

    # Characters 00080 - 007FF
    OUTPUT_CHR=$( echo -en "\\${BYTE_2}\\${BYTE_1}" )

  elif [ $INT_NUM -ge 2048 ] && [ $INT_NUM -lt 65536 ]; then
    BYTE_1=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:15:6}" | bc )
    BYTE_2=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:9:6}" | bc )
    BYTE_3=$( echo -n "ibase=2; obase=8; 1110${BIN_WORD:5:4}" | bc )
    
    # Characters 00800 - 0FFFF
    OUTPUT_CHR=$( echo -en "\\${BYTE_3}\\${BYTE_2}\\${BYTE_1}" )

  elif [ $INT_NUM -ge 65536 ] && [ $INT_NUM -lt 179247 ]; then
    # NOTE: Upper limit of UTF-8 is 1114111, but we stop before the
    #       currently unused character ranges.
    BYTE_1=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:15:6}" | bc )
    BYTE_2=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:9:6}" | bc )
    BYTE_3=$( echo -n "ibase=2; obase=8; 10${BIN_WORD:3:6}" | bc )
    BYTE_4=$( echo -n "ibase=2; obase=8; 11110${BIN_WORD:0:3}" | bc )
    
    # Characters 10000 - 10FFFF
    OUTPUT_CHR=$( echo -en "\\${BYTE_4}\\${BYTE_3}\\${BYTE_2}\\${BYTE_1}" )

  fi

  case "${OUTPUT_CHR}" in
    [^[:print:]])
      echo -n "" && return 0
      ;;
    [[:print:]])
      # NOTE: This condition passes code 160 (&nbsp;).
      echo -en "${OUTPUT_CHR}"
      ;;
  esac
)

utf8_sanitize() {
  INT_NUM=$( \
    echo -n $1 | \
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

  # Empty Cells as of 05/14/2021:
  #
  # 0000-0020, 007F-009F, 0149, 0378-0379, 0380-0383, 038B, 038D, 03A2, 0557-0558, 058B-058C,
  # 0590, 05C8-05CF, 05Eb-05EE, 05F5-05FF, 061C-061D, 070E-070F, 074B-074C, 07B2-07BF,
  # 07FB-07FC, 082E-082F, 083F, 085C-085D, 085F-086F, 08B5, 08BE-08E2, 0984, 098D-098E,
  # 0991-0992, 09A9, 09B1, 09B3-09B5, 09BA-09BB, 09C5-09C6, 09C9-09CA, 09CF-09D6, 09D8-09DB,
  # 09DE, 09E4-09E5, 09FC-0A00, 0A04, 0A0B-0A0E, 0A11-0A12, 0A29, 0A31, 0A37, 0A3A-0A3B,
  # 0A3D, 0A43-0A46, 0A49-0A4A, 0A4E-0A50, 0A52-0A58, 0A5D, 0A5F-0A65, 0A76-0A80, 0A84, 0A8E,
  # 0A92, 0AA9, 0AB1, 0AB4, 0ABA-0ABB, 0AC6, 0ACA, 0ACE-0ACF, 0AD1-0ADF, 0AE4-0AE5, 0AF2-0AF8,
  # 0AFA-0B00, 0B04, 0B0D-0B0E, 0B11-0B12, 0B29, 0B31, 0B34, 0B3A-0B3B, 0B45-0B46, 0B55,
  # 0B58-0B5B, 0B5E, 0B64-0B65, 0B78-0B81, 0B84, 0B8B-0B8D, 0B91, 0B96-0B98, 0B9B, 0B9D,
  # 0BA0-0BA2, 0BA5-0BA7, 0BAB-0BAD, 0BBA-0BBD, 0BC3-0BC5, 0BC9, 0BCE-0BCF, 0BD1-0BD6,
  # 0BD8-0BE5, 0BFB-0BFF, 0C04, 0C0D, 0C11, 0C29, 0C3A-0C3C, 0C45, 0C49, 0C4E-0C54, 0C57,
  # 0C5B-0C5F, 0C64-0C65, 0C70-0C77, 0C84, 0C8D, 0C91, 0CA9, 0CB4, 0CBA-0CBB, 0CC5, 0CC9,
  # 0CCE-0CD4, 0CD7-0CD0, 0CDF, 0CE4-0CE5, 0CF0, 0CF3-0D00, 0D0D, 0D11, 0D3B-0D3C, 0D45,
  #
  # Started on Section "Malayalam".
}