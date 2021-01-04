#!/bin/sh

cmd_01() { apk.static add gnupg; };
cmd_02() { mkdir -pm 0700 /pgp/keys; };
cmd_03() { mkdir -m 0700 /pgp/phrases; };
cmd_04() { [ ! "$(ls -A /pgp/keys/ 2>/dev/null)" ] && pgp_generate_and_run_batch "$(pgp_generate_pass_phrases)"; };
cmd_05() { [ ! "$(ls -A /pgp/keys/ 2>/dev/null)" ] && pgp_export_keys; };
cmd_06() { [ ! "$(ls -A /pgp/phrases/ 2>/dev/null)" ] && pgp_ask_for_32_byte_hex; };
cmd_07() { [ ! "$(ls -A /pgp/phrases/ 2>/dev/null)" ] && pgp_ask_for_16_byte_hex; };
cmd_08() { [ ! "$(ls -A /pgp/keys/ 2>/dev/null)" ] && pgp_encrypt_pass_phrases; };
cmd_len() { echo 08; };