#!/bin/sh

# Utility function for escaping special characters in a string.
# Usage:
# escape_string <string_to_escape>
escape_string() {
  [[ ! -z $1 ]] && echo -n $(echo $1 | sed -e 's/[[:punct:]]/\\&/g')
}