#!/bin/sh

# Name: pretty
# Desc: A utility function for echoing important messages as aesthetically pleasing
#       horizontal bars that span the terminal.

pretty() {
  local TXT=
  local HDR=" • "
  local MSG=
  local CLR="\033[1;37m\033[43m"
  local BLK="\033[0m"
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
        [ "${HDR}" == " • " ] && HDR=" WAIT: "
        ;;
      -P|--passed)
        # User is indicating result passed.
        [ $IS_TEST -eq 0 ] && \
        [ $IS_PASS -eq 0 ] && \
        [ $IS_FAIL -eq 0 ] && IS_PASS=1
        [ "${CLR}" == "\033[1;37m\033[43m" ] && CLR="\033[1;37m\033[42m"
        [ -z "${MSG}" ] && MSG="PASSED!"
        ;;
      -F|--failed)
        # User is indicating result failed.
        [ $IS_TEST -eq 0 ] && \
        [ $IS_PASS -eq 0 ] && \
        [ $IS_FAIL -eq 0 ] && IS_FAIL=1
        [ "${CLR}" == "\033[1;37m\033[43m" ] && CLR="\033[1;37m\033[41m"
        [ -z "${MSG}" ] && MSG="FAILED."
        ;;
      -E|--error)
        # User is indicating an error occurred.
        [ "${HDR}" == " • " ] && HDR=" ERROR: "
        [ "${CLR}" == "\033[1;37m\033[43m" ] && CLR="\033[1;37m\033[41m"
        ;;
      *)
        # The message text, collected word by word.
        [ -z "${TXT}" ] && TXT="${ARG}" || TXT="${TXT} ${ARG}"
        ;;
    esac
  done

  [ -z "${TXT}" ] && \
  [ $IS_PASS -eq 0 ] && \
  [ $IS_FAIL -eq 0 ] && return 0 # Nothing was passed in, exit gracefully.

  local TTY_LEN=$(stty size | awk '{print $2}')
  local TXT_LEN=${#TXT}
  local MSG_LEN=
  local HDR_LEN=${#HDR}
  local MAX_LEN=
  [ -z "${MSG}" ] && MSG_LEN=10 || MSG_LEN=$((${#MSG} + 3))

  if [ $IS_TEST -eq 1 ]; then
    MAX_LEN=$(($TTY_LEN - $HDR_LEN - $MSG_LEN))
  elif [ $IS_PASS -eq 1 ] || [ $IS_FAIL -eq 1 ]; then
    echo -e "${CLR} ${MSG}  ${BLK}" && return 0 # Our work is done, exit gracefully.
  else
    MAX_LEN=$(($TTY_LEN - $HDR_LEN))
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
          echo -e "${CLR}${HDR}${TMP_TXT}${DIFF_STR}${BLK}"
          TMP_TXT="${TMP_WORD}"
        else
          TMP_TXT="${TMP_TXT} ${TMP_WORD}"
        fi
      fi
    done
    DIFF_LEN=$(($MAX_LEN - ${#TMP_TXT}))
    DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
    [ $IS_TEST -eq 1 ] && \
    echo -e -n "${CLR}${HDR}${TMP_TXT}${DIFF_STR}${BLK}" || \
    echo -e "${CLR}${HDR}${TMP_TXT}${DIFF_STR}${BLK}"
  else
    DIFF_LEN=$(($MAX_LEN - $TXT_LEN))
    DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
    [ $IS_TEST -eq 1 ] && \
    echo -e -n "${CLR}${HDR}${TXT}${DIFF_STR}${BLK}" || \
    echo -e "${CLR}${HDR}${TXT}${DIFF_STR}${BLK}"
  fi
}