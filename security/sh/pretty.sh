#!/bin/sh

# Name: pretty
# Desc: A utility function for echoing important messages as aesthetically pleasing
#       horizontal bars that span the terminal.

export PRETTY_DISPLAY_GLOBAL=
export PRETTY_FG_COLOR_GLOBAL=
export PRETTY_BG_COLOR_GLOBAL=

pretty() {
  local HDR=" • "
  local FTR=
  local FG_COLOR_DEFAULT="\033[1;37m"
  local BG_COLOR_DEFAULT="\033[43m"
  local RESET_COLORS="\033[0m"
  local IS_TEST=0
  local IS_PASS=0
  local IS_FAIL=0

  for ARG in "${@}"; do
    local LEADING_DASHES="$(echo -n ${ARG} | sed 's/^\([-]\{1,2\}\).*$/\1/g')"
    # Parse out leading dashes, if any.

    if [ "${LEADING_DASHES}" == "-" ] || [ "${LEADING_DASHES}" == "--" ]; then
    # This argument is possibly a flag beginning with one or two dashes.
      if [ "$(echo -n ${ARG} | sed 's/.*\([=]\{1\}\).*/\1/g')" == "=" ]; then
      # This argument is possibly a color flag containing an equal sign.
        if [ "$(echo ${ARG} | sed 's/.*\(fg\).*/\1/g')" == "fg" ]; then
        # Adjust foreground color, once per call of `pretty`.
          if [ -z "${PRETTY_FG_COLOR_GLOBAL}" ]; then
            PRETTY_FG_COLOR_GLOBAL=$( \
              echo ${ARG} | \
              cut -d '=' -f 2 | \
              sed "s/\"\([^ ]\{1,\}\)\"/\1/g" \
            )
          fi
        elif [ "$(echo ${ARG} | sed 's/.*\(bg\).*/\1/g')" == "bg" ]; then
        # Adjust background color, once per call of `pretty`.
          if [ -z "${PRETTY_BG_COLOR_GLOBAL}" ]; then
            PRETTY_BG_COLOR_GLOBAL=$( \
              echo ${ARG} | \
              cut -d '=' -f 2 | \
              sed "s/\"\([^ ]\{1,\}\)\"/\1/g" \
            )
          fi
        fi
      else
      # This argument is possibly a non-color flag, so test them all using a case statement.
        case $ARG in
          -T|--test)
          # User anticipates a pass/fail result of test.
            [ $IS_TEST -eq 0 ] && \
            [ $IS_PASS -eq 0 ] && \
            [ $IS_FAIL -eq 0 ] && IS_TEST=1
            [ "${HDR}" == " • " ] && HDR=" WAIT: "
            ;;
          -P|--passed)
          # User is indicating test result passed.
            [ $IS_TEST -eq 0 ] && \
            [ $IS_PASS -eq 0 ] && \
            [ $IS_FAIL -eq 0 ] && IS_PASS=1
            [ -z "${PRETTY_BG_COLOR_GLOBAL}" ] && PRETTY_BG_COLOR_GLOBAL="\033[42m"
            [ -z "${FTR}" ] && FTR="PASSED!"
            ;;
          -F|--failed)
          # User is indicating test result failed.
            [ $IS_TEST -eq 0 ] && \
            [ $IS_PASS -eq 0 ] && \
            [ $IS_FAIL -eq 0 ] && IS_FAIL=1
            [ -z "${PRETTY_BG_COLOR_GLOBAL}" ] && PRETTY_BG_COLOR_GLOBAL="\033[41m"
            [ -z "${FTR}" ] && FTR="FAILED."
            ;;
          -E|--error)
          # User is indicating an error occurred.
            [ "${HDR}" == " • " ] && HDR=" ERROR: "
            [ -z "${PRETTY_BG_COLOR_GLOBAL}" ] && PRETTY_BG_COLOR_GLOBAL="\033[41m"
            ;;
          *)
          # Do nothing in the edge case(s).
            echo ' ' >/dev/null 2>&1
            ;;
        esac
      fi
    else
    # Having exhausted all other options, this argument must be the message text.
      [ -z "${PRETTY_DISPLAY_GLOBAL}" ] && PRETTY_DISPLAY_GLOBAL="${ARG}"
    fi
  done

  # --------------------------------------------------------------------------------------
  [ -z "${PRETTY_DISPLAY_GLOBAL}" ] && \
  [ $IS_PASS -eq 0 ] && \
  [ $IS_FAIL -eq 0 ] && return 0 # Nothing was passed in, exit gracefully.
  # --------------------------------------------------------------------------------------

  local NOT_A_TTY_IF_EMPTY=
  # Assign this value in a subshell to prevent error message(s) from printing to terminal.
  ( NOT_A_TTY_IF_EMPTY="$(stty size | tr '\n' ' ')" ) >/dev/null 2>&1

  # Because stty fails during build stages, we must prevent errors by
  # conditionally using a fixed size of 60 (50% of smallest screen
  # resolution setting).
  local TTY_LEN=
  [ -z "${NOT_A_TTY_IF_EMPTY}" ] && \
  TTY_LEN=60 || \
  TTY_LEN=$( \
    echo -n "${NOT_A_TTY_IF_EMPTY}" | \
    awk '{print $2}' \
  )

  local TXT_LEN=${#PRETTY_DISPLAY_GLOBAL}
  local FTR_LEN=
  local HDR_LEN=${#HDR}
  local MAX_LEN=

  [ -z "${FTR}" ] && FTR_LEN=10 || FTR_LEN=$((${#FTR} + 3))
  
  if [ $IS_TEST -eq 1 ]; then
    # Truncate the length of the displayed message bar to make room for test result.
    MAX_LEN=$(($TTY_LEN - $HDR_LEN - $FTR_LEN))
    
  elif [ $IS_PASS -eq 1 ] || [ $IS_FAIL -eq 1 ]; then
    # Use default foreground color if none has been assigned.
    [ -z "${PRETTY_FG_COLOR_GLOBAL}" ] && PRETTY_FG_COLOR_GLOBAL=$FG_COLOR_DEFAULT
    
    # Print the message ("PASSED!" / "FAILED.")
    echo -e "${PRETTY_FG_COLOR_GLOBAL}${PRETTY_BG_COLOR_GLOBAL} ${FTR}  ${RESET_COLORS}"

    # Reset all globals in advance of next call of `pretty`.
    PRETTY_FG_COLOR_GLOBAL=
    PRETTY_BG_COLOR_GLOBAL=
    PRETTY_DISPLAY_GLOBAL=

    # Our work is done, exit gracefully.
    return 0
  else
    # Take full, non-truncated measurement of available space.
    MAX_LEN=$(($TTY_LEN - $HDR_LEN))
  fi

  local DIFF_LEN=
  local DIFF_STR=

  # Use default colors if none have been assigned.
  [ -z "${PRETTY_FG_COLOR_GLOBAL}" ] && PRETTY_FG_COLOR_GLOBAL=$FG_COLOR_DEFAULT
  [ -z "${PRETTY_BG_COLOR_GLOBAL}" ] && PRETTY_BG_COLOR_GLOBAL=$BG_COLOR_DEFAULT

  if [ $TXT_LEN -gt $MAX_LEN ]; then
  # If the message to be displayed exceeds the available space...
    local TMP_TXT=
    for TMP_WORD in $PRETTY_DISPLAY_GLOBAL; do
    # ...We need to iterate over the words one at a time before printing to terminal.
      local WORD_LEN=${#TMP_WORD}

      if [ $WORD_LEN -ge $MAX_LEN ]; then
        local DOT_STR="... "
        local WORD_MAX=$(($MAX_LEN - ${#DOT_STR}))
        TMP_WORD="${TMP_WORD:0:$WORD_MAX}${DOT_STR}"
      fi

      if [ -z "${TMP_TXT}" ]; then
        # Initialize TMP_TXT with the first word.
        TMP_TXT="${TMP_WORD}"
      else
        if [ $((${#TMP_TXT} + ${#TMP_WORD})) -gt $MAX_LEN ]; then
        # If adding TMP_WORD to TMP_TXT will exceed available space...
          DIFF_LEN=$(($MAX_LEN - ${#TMP_TXT}))
          DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
          # Take measurements based on the words we have read from PRETTY_DISPLAY_GLOBAL so far, then print TMP_TXT to terminal.
          echo -e "${PRETTY_FG_COLOR_GLOBAL}${PRETTY_BG_COLOR_GLOBAL}${HDR}${TMP_TXT}${DIFF_STR}${RESET_COLORS}"
          # Overwrite TMP_TXT with TMP_WORD.
          TMP_TXT="${TMP_WORD}"
        else
        # If adding TMP_WORD to TMP_TXT will not exceed available space, append TMP_WORD to TMP_TXT.
          TMP_TXT="${TMP_TXT} ${TMP_WORD}"
        fi
      fi
    done
    
    # Take measurements based on final line of multi-line display.
    DIFF_LEN=$(($MAX_LEN - ${#TMP_TXT}))
    DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
    # Conditionally truncate based on presence of "-T|--test" flag.
    [ $IS_TEST -eq 1 ] && \
    echo -e -n "${PRETTY_FG_COLOR_GLOBAL}${PRETTY_BG_COLOR_GLOBAL}${HDR}${TMP_TXT}${DIFF_STR}${RESET_COLORS}" || \
    echo -e "${PRETTY_FG_COLOR_GLOBAL}${PRETTY_BG_COLOR_GLOBAL}${HDR}${TMP_TXT}${DIFF_STR}${RESET_COLORS}"
  else
    # Take measurements based on display text.
    DIFF_LEN=$(($MAX_LEN - $TXT_LEN))
    DIFF_STR="$(printf '%*s' "${DIFF_LEN}")"
    # Conditionally truncate based on presence of "-T|--test" flag.
    [ $IS_TEST -eq 1 ] && \
    echo -e -n "${PRETTY_FG_COLOR_GLOBAL}${PRETTY_BG_COLOR_GLOBAL}${HDR}${PRETTY_DISPLAY_GLOBAL}${DIFF_STR}${RESET_COLORS}" || \
    echo -e "${PRETTY_FG_COLOR_GLOBAL}${PRETTY_BG_COLOR_GLOBAL}${HDR}${PRETTY_DISPLAY_GLOBAL}${DIFF_STR}${RESET_COLORS}"
  fi
  # Reset all globals in advance of next call of `pretty`.
  PRETTY_FG_COLOR_GLOBAL=
  PRETTY_BG_COLOR_GLOBAL=
  PRETTY_DISPLAY_GLOBAL=
}