#!/bin/bash

_here_="$(dirname "$0")"

source "$_here_/00-create-admin-user.sh"
source "$_here_/01-create-api-user.sh"
source "$_here_/02-auth-api-user.sh"

# Call the initialization functions.
init_00
init_01
init_02