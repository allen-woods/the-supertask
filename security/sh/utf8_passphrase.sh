#!/bin/sh
utf8_passphrase() {
  local PHRASE_I=1
  local PHRASE_LEN=$1
  local PHRASE=
  local BYTE_COUNT=0

  local CHAR_FILE=$HOME/.aes_rsa_utf8_support/character_set/char_file.utf8

  [ ! -f $CHAR_FILE ] && \
    echo "ERROR: Please run \"utf8_make_char_file\" before proceeding." && \
    return 1

  [ ! -z "$( ( jot ) 2>&1 | grep -o "not found" )" ] && \
    apk update && \
    apk --no-cache add outils-jot=0.9-r0

  # Create a random passphrase.
  while [ $PHRASE_I -le $PHRASE_LEN ]; do
    # Line selection.
    local LINE_MAX=$( \
      wc -l $CHAR_FILE | \
      awk '{ print $1 }' \
    )
    local LINE_RND=$( \
      jot -w %i -r 1 1 \
      $(( $LINE_MAX + 1 )) \
    )
    local LINE_TXT="$( \
      sed "${LINE_RND}q;d" \
      $CHAR_FILE \
    )"

    # Character selection.
    local CHAR_MAX=${#LINE_TXT}
    local CHAR_RND=$( \
      jot -w %i -r 1 1 \
      $CHAR_MAX \
    )
    local CHAR_TXT=$( \
      echo $LINE_TXT | \
      sed 's|.|&\ |g' | \
      cut -d ' ' -f $CHAR_RND \
    )
    local CHAR_BYTES=$( \
      echo -n "${CHAR_TXT}" | \
      od -b | \
      tr -d '\n' | \
      sed 's|^.*\([1-4]\{1\}\)$|\1|' \
    )
    if [ $BYTE_COUNT -eq 0 ]; then
      BYTE_COUNT=$(( $BYTE_COUNT + $CHAR_BYTES ))
      # Place character into generated passphrase.
      [ -z "${PHRASE}" ] && PHRASE="${CHAR_TXT}"
    elif [ $BYTE_COUNT -gt 0 ]; then
      if [ $(( $BYTE_COUNT + $CHAR_BYTES )) -gt $PHRASE_LEN ]; then
        # Loading even one more character will be too many bytes.
        # We must halt the loop and echo our "nearest-bytes" phrase.
        break
      else
        BYTE_COUNT=$(( $BYTE_COUNT + $CHAR_BYTES ))
        # Place character into generated passphrase.
        PHRASE="${PHRASE}${CHAR_TXT}"
      fi
    fi
    PHRASE_I=$(( $PHRASE_I + 1 ))
  done
  
  if [ ! -z "${PHRASE}" ]; then
    # Because the output of this function is meant to be piped into a parameter- or field-value,
    # we echo the generated passphrase without a newline for convenience.
    echo -e "${PHRASE}" | tr -d '\n'
  fi
}