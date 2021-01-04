#!/bin/sh

# NOTE: pass incoming data in the form ''"${data}"''

function pipe_write {
  local pipe=${1:-"test"}
  local data=${2:-"the quick brown fox jumps over the lazy dog"}
  local flag=${3:-"--append"}
  local first_run=0
  local sync=

  if [ ! -p $pipe ]
  then
    # Create the pipe if it doesn't exist.
    mkfifo $pipe

    # Prevent privilege escalation attacks on pipe.
    chown root:root $pipe

    # Restrict access to the pipe, write only.
    su root -c "chmod 0200 ${pipe}"
    
    # Set `first_run` for proper data handling below.
    first_run=1
  fi

  if [ $first_run -eq 0 ] && [ "${flag}" == "--overwrite" ]
  then
    # Restrict access to the pipe, read-write only.
    su root -c "chmod 0600 ${pipe}"

    # Empty the pipe completely, and silently.
    ( ( echo ' ' >> $pipe & ) && echo "$(cat < ${pipe})" ) > /dev/null 2>&1

    # Restrict access to the pipe, write only.
    su root -c "chmod 0200 ${pipe}"
    
    # Set `first_run` for proper data handling below.
    first_run=1
  fi

  if [ $first_run -eq 0 ] && [[ -z $sync ]]
  then
    # Restrict access to the pipe, read only.
    su root -c "chmod 0400 ${pipe}"

    # If we are appending data, front-load contents of pipe.
    sync=''"$(cat < ${pipe})"''

    # Restrict access to the pipe, write only.
    su root -c "chmod 0200 ${pipe}"
  fi

  for item in $data
  do
    if [ $first_run -eq 1 ]
    then
      # Pipe is empty, place first item into `sync`.
      sync=''"${item}"''

      # Unset `first_run` to indicate start of data collection.
      first_run=0
    else
      # Data has collected at least one thing, append item to `sync`.
      sync=''"$(printf "%s\n" ''"${sync}"'' ''"${item}"'')"''
    fi
  done

  # Restrict access to the pipe, write only.
  su root -c "chmod 0200 ${pipe}"

  # Silently place contents of `sync` into pipe. 
  ( echo ''"${sync}"'' > $pipe & )

  # Restrict all access to the pipe.
  # (Applying 0100 causes `ps` output to hang; hacky "not allowed".)
  su root -c "chmod 0100 ${pipe}"
}