check_for_existing_pgp_keys() {
  keys=$(ls -A /pgp/keys 2>/dev/null)
  [ ${#keys} -gt 0 ] && return 1
}
check_for_existing_phrases() {
  phrases=$(ls -A /pgp/phrases 2>/dev/null)
  [ ${#phrases} -gt 0 ] && return 1
}
