#!/bin/sh

function pipe_read {
  local pipe=${1:-"test"}
  local item=${2:-0}
  local flag=${3:-"--no-delete"}
  local sync=
  local data=

  # Require the pipe to exist so we can read from it.
  if [ -p $pipe ] && [[ ! -z $pipe ]]
  then
    # Restrict access to the pipe, read only.
    su root -c "chmod 0400 ${pipe}"

    # Extract the contents of the pipe.
    sync=''"$(cat < ${pipe})"''

    if [ $item -eq 0 ]
    then
      # Place all `sync` data into requested `data`.
      data=''"${sync}"''

    elif [ $item -gt 0 ]
    then
      # Place requested item from `sync` into `data`.
      data=''"$(echo ''"${sync}"'' | sed "${item}q;d")"''

    fi

    if [ "${flag}" == "--no-delete" ]
    then
      # Restrict access to the pipe, write only.
      su root -c "chmod 0200 ${pipe}"

      # Pass all previous `sync` data back into pipe.
      ( echo ''"${sync}"'' > $pipe & ) > /dev/null 2>&1

      # Restrict access to the pipe, read only.
      su root -c "chmod 0400 ${pipe}"

    elif [ "${flag}" == "--item-only" ] && [ $item -gt 0 ]
    then
      # Restrict access to the pipe, write only.
      su root -c "chmod 0200 ${pipe}"

      # Pass only requested `data` (item) back into pipe.
      ( echo ''"${data}"'' > $pipe & ) > /dev/null 2>&1

      # Restrict access to the pipe, read only.
      su root -c "chmod 0400 ${pipe}"

    elif [ "${flag}" == "--delete-item" ] && [ $item -gt 0 ]
    then
      # Parse the remaining items, if any.
      local remaining=''"$(echo ''"${sync}"'' | sed "${item}d")"''

      if [[ -z $remaining ]]
      then
        # Delete the now empty pipe, silently.
        ( su root -c "rm -f ${pipe}" ) > /dev/null 2>&1

      else
        # Restrict access to the pipe, write only.
        su root -c "chmod 0200 ${pipe}"

        # Pass mutated data back into pipe with `item` removed.
        ( echo ''"${remaining}"'' > $pipe & ) > /dev/null 2>&1

        # Restrict access to the pipe, read only.
        su root -c "chmod 0400 ${pipe}"

      fi

    elif [ "${flag}" == "--delete-all" ]
    then
      # Delete the pipe, silently.
      ( su root -c "rm -f ${pipe}" ) > /dev/null 2>&1

    fi

    if [ -p $pipe ] && [[ -z $pipe ]]
    then
      # Restrict all access to the pipe.
      # (Applying 0100 causes `ps` output to hang; hacky "not allowed".)
      su root -c "chmod 0100 ${pipe}"

    fi

    # Send the requested `data` to stdout.
    echo ''"${data}"''
  fi
}