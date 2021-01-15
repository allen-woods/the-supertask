#!/bin/sh

# Name: install_lib.sh
# Desc: A collection of methods that must be called in proper sequence to install a specific set of data.
#       Certain methods are standardized and must appear, as follows:
#         - check_skip_install    A method for checking if the install should be skipped.
#         - create_instructions   A method for creating a non-blocking pipe to store instruction names.
#         - read_instruction      A method for reading instruction names from the non-blocking pipe.
#         - update_instructions   A method for placing instruction names into the non-blocking pipe.
#         - delete_instructions   A method for deleting the non-blocking pipe and any instructions inside.
#       All methods must accept a single argument, OPT, whose value is assumed to always be 0, 1, or 2.
#       Evaluations of OPT should be interpreted as follows:
#         - 0: Output of any kind must be silenced using redirection to `/dev/null 2>&1`.
#         - 1: Status messages should be sent to stdout, all other output(s) silenced.
#         - 2: All output should be sent to stdout and `--verbose` options should be applied wherever possible.

create_instructions() {
  local OPT=$1
  case $OPT in
    0)
      # quiet
    1)
      # status
    2)
      # verbose
    *)
      # do nothing
  esac
  mkfifo /tmp/instructs
  exec 3<> /tmp/instructs
  unlink /tmp/instructs
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
  exec 3>&-
  rm -f /tmp/instructs
}