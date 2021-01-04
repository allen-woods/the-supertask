# This is an example of bold white text with red background:
# echo -e "\033[38;2;255;255;255;48;2;255;0;0;1mTesting...\033[0m"

# prettyStatusHeader() {
#   local TWIDTH=$(stty size | grep -o '\ [[:digit:]]\{1,\}')
#   local PADSPACE="$(head -c ${TWIDTH} < /dev/zero | tr '\0' '\32')"
# }

# This will be a strong visual feedback for status messages and installation progress.

pretty_print_header() {
  local PATH_STRING="$(pwd)"
  if [ "${PATH_STRING}" == "/" ]
  then
    # Just use the slash.
  else
    # Use the address broken by "/"
}