#!/bin/sh
utf8_passphrase() (
  PHRASE_I=1
  PHRASE_LEN=$1
  PHRASE=

  CHAR_FILE=$HOME/.aes_rsa_utf8_support/character_set/char_file.utf8

  [ ! -f $CHAR_FILE ] && \
  echo "ERROR: Please run \"utf8_make_char_file\" before proceeding." && \
  return 1

  [ ! -z "$( ( jot ) 2>&1 | grep -o "not found" )" ] && \
  apk update && \
  apk --no-cache add outils-jot=0.9-r0

  # Create a random passphrase.
  while [ $PHRASE_I -le $PHRASE_LEN ]; do
    # Line selection.
    LINE_MAX=$( wc -l $CHAR_FILE | awk '{ print $1 }' )
    LINE_RND=$( jot -w %i -r 1 1 $(($LINE_MAX + 1)) )
    LINE_TXT="$( sed "${LINE_RND}q;d" $CHAR_FILE )"
    # Character selection.
    CHAR_MAX=${#LINE_TXT}
    CHAR_RND=$( jot -w %i -r 1 1 $CHAR_MAX )
    CHAR_TXT=$( echo $LINE_TXT | sed 's|.|&\ |g' | cut -d ' ' -f $CHAR_RND )
    # Place character into generated passphrase.
    [ -z "${PHRASE}" ] && PHRASE="${CHAR_TXT}" || PHRASE="${PHRASE}${CHAR_TXT}"
    # Increment
    PHRASE_I=$(($PHRASE_I + 1))
  done
  
  if [ ! -z "${PHRASE}" ]; then
    echo -e "${PHRASE}"
  fi
)