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
    
    # Set `first_run` for proper data handling below.
    first_run=1
  fi

  if [ $first_run -eq 0 ] && [ "${flag}" == "--overwrite" ]
  then
    # Empty the pipe completely, and silently.
    ( ( echo ' ' >> $pipe & ) && echo "$(cat < ${pipe})" ) > /dev/null 2>&1
    
    # Set `first_run` for proper data handling below.
    first_run=1
  fi

  if [ $first_run -eq 0 ] && [[ -z $sync ]]
  then
    # If we are appending data, front-load contents of pipe.
    sync=''"$(cat < ${pipe})"''
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

  # Silently place contents of `sync` into pipe. 
  ( echo ''"${sync}"'' > $pipe & )
}