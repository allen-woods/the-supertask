#!/bin/sh

# Name: install_lib.sh
# Desc: A collection of methods that must be called in proper sequence to install a specific set of data.
#       Certain methods are standardized and must appear, as follows:
#         - check_skip_install    A method for checking if the install should be skipped.
#         - create_instructions   A method for creating a non-blocking pipe to store instruction names.
#         - read_instruction      A method for reading instruction names from the non-blocking pipe.
#         - update_instructions   A method for placing instruction names into the non-blocking pipe.
#         - delete_instructions   A method for deleting the non-blocking pipe and any instructions inside.
#         - pretty_print          A method for printing text in a concise, colorful, "pretty" way.
#
#       All methods must accept a single argument, OPT, whose value is assumed to always be 0, 1, or 2.
#       Evaluations of OPT should be interpreted as follows:
#         - 0: Output of any kind must be silenced using redirection to `/dev/null 2>&1`.
#         - 1: Status messages should be sent to stdout, all other output(s) silenced.
#         - 2: All output should be sent to stdout and `--verbose` options should be applied wherever possible.
#
# * * * BEGIN STANDARDIZED METHODS  * * * * * * * * * * * * * *

check_skip_install() {
  # Steps required to confirm already installed go here.
}

create_instructions() {
  local OPT=$1
  case $OPT in
    0)
      # completely silent * * * * * * * * * * * * * * * * * * *
      #
      exec 4>/dev/null  # stdout:   disabled  (Shell process)
      exec 5>/dev/null  # echo:     disabled  (Status command)
      exec 2>/dev/null  # stderr:   disabled
      set +v #          # verbose:  disabled
      ;;
    1)
      # status only * * * * * * * * * * * * * * * * * * * * * *
      #
      exec 4>/dev/null  # stdout:   disabled  (Shell process)
      exec 5>&1         # echo:     ENABLED   (Status command)
      exec 2>/dev/null  # stderr:   disabled
      set +v #          # verbose:  disabled
      ;;
    2)
      # verbose * * * * * * * * * * * * * * * * * * * * * * * *
      #
      exec 4>&1         # stdout:   ENABLED   (Shell process)
      exec 5>&1         # echo:     ENABLED   (Status command)
      exec 2>&1         # stderr:   ENABLED
      set -v #          # verbose:  ENABLED
      ;;
    *)
      # do nothing  * * * * * * * * * * * * * * * * * * * * * *
      #
  esac

  mkfifo /tmp/instructs 1>&4
  echo "Created pipe for instructions." 1>&5

  exec 3<> /tmp/instructs 1>&4
  echo "Executed file descriptor to unblock pipe." 1>&5

  unlink /tmp/instructs 1>&4
  echo "Unlinked the unblocked pipe." 1>&5
}

read_instruction() {
  read -u3 INSTALL_FUNC_NAME
}

update_instructions() {
  printf '%s\n' \
  instruct \
  names \
  go \
  here 1>&3
}

delete_instructions() {
  exec 2>&1             # Restore stderr
  exec 3>&-             # Remove file descriptor 3
  exec 4>&-             # Remove file descriptor 4
  exec 5>&-             # Remove file descriptor 5
  rm -f /tmp/instructs  # Force deletion of pipe
  set +v #              # Cancel verbose mode
}

# EXAMPLE SYNTAX:
# pretty_print  -H|--header -N|--name="name of setion"  -D|--desc="desription of section"
# pretty_print  -B|--body   -M|--message="message text" -C|--class="class_name"
# pretty_print  -F|--footer -T|--text="text to display"
pretty_print() {
  # TODO: Write this function.
}

# * * * END STANDARDIZED METHODS  * * * * * * * * * * * * * * *