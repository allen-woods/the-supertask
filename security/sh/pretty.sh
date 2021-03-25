#!/bin/sh

pretty() {
  local TXT=
  local CLR="\033[7;33m"
  local BLK="\033[0m"
  local MSG=
  local IS_TEST=0
  local IS_PASS=0
  local IS_FAIL=0

  for ARG in "$@"; do
    case $ARG in
      -T|--test)
        # User anticipates a pass/fail result.
        [ $IS_TEST -eq 0 ] && \
        [ $IS_PASS -eq 0 ] && \
        [ $IS_FAIL -eq 0 ] && IS_TEST=1
        ;;
      -P|--passed)
        # User is indicating result passed.
        [ $IS_PASS -eq 0 ] && \
        [ $IS_FAIL -eq 0 ] && IS_PASS=1
        [ "${CLR}" == "\033[7;33m" ] && CLR="\033[7;32m"
        [ -z "${MSG}" ] && MSG="PASSED!"
        ;;
      -F|--failed)
        # User is indicating result failed.
        [ $IS_FAIL -eq 0 ] && \
        [ $IS_PASS -eq 0 ] && IS_FAIL=1
        [ "${CLR}" == "\033[7;33m" ] && CLR="\033[7;31m"
        [ -z "${MSG}" ] && MSG="FAILED."
        ;;
      *)
        # The message text, collected word by word.
        [ -z "${TXT}" ] && TXT="${ARG}" || TXT="${TXT} ${ARG}"
        ;;
    esac
  done

  [ -z "${TXT}" ] && return 0 # Nothing was passed in, exit gracefully.

  local TTY_LEN=$(stty size | awk '{print $1}')
  local TXT_LEN=${#TXT}
  local MSG_LEN=$((${#MSG} + 3))
  local MAX_LEN=

  if [ $IS_TEST -eq 1 ]; then
    MAX_LEN=$(($TTY_LEN - $MSG_LEN))
  elif [ $IS_PASS -eq 1 ] || [ $IS_FAIL -eq 1 ]; then
    echo -e "${CLR} ${MSG}  ${BLK}" && return 0 # Our work is done, exit gracefully.
  else
    MAX_LEN=$TTY_LEN
  fi

  local DIFF_LEN=
  local DIFF_STR=

  if [ $TXT_LEN -gt $MAX_LEN ]; then
    local TMP_TXT=
    for TMP_WORD in $TXT; do
      if [ -z "${TMP_TXT}" ]; then
        TMP_TXT="${TMP_WORD}"
      else
        if [ $((${#TMP_TXT} + ${#TMP_WORD})) -gt $MAX_LEN ]; then
          DIFF_LEN=$(($MAX_LEN - ${#TMP_TXT}))
          DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
          echo -e "${CLR}${TMP_TXT}${DIFF_STR}${BLK}"
          TMP_TXT="${TMP_WORD}"
        else
          TMP_TXT="${TMP_TXT} ${TMP_WORD}"
        fi
      fi
    done
    DIFF_LEN=$(($MAX_LEN - ${#TMP_TXT}))
    DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
    [ $IS_TEST -eq 1 ] && \
    echo -e -n "${CLR}${TMP_TXT}${DIFF_STR}${BLK}" || \
    echo -e "${CLR}${TMP_TXT}${DIFF_STR}${BLK}"
  else
    DIFF_LEN=$(($MAX_LEN - $TXT_LEN))
    DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
    [ $IS_TEST -eq 1 ] && \
    echo -e -n "${CLR}${TXT}${DIFF_STR}${BLK}" || \
    echo -e "${CLR}${TXT}${DIFF_STR}${BLK}"
  fi
}