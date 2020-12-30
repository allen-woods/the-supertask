#!/bin/sh

# Utility function for escaping special characters in a string.
# Usage:
# escapeString <string_to_escape>
escapeString() {
  [[ ! -z $1 ]] && echo -n $(echo $1 | sed -e 's/[[:punct:]]/\\&/g')
}