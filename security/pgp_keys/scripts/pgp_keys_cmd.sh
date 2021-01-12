#!/bin/sh

# TODO: Rewrite these functions to not cd into other directories, or at least to go back to the original directory once finished.

cmd_01() { export SKIP_INSTALL="$(ls -A /pgp/keys/ 2>/dev/null)$(ls -A /pgp/phrases/ 2>/dev/null)"; };
cmd_02() { [ ! "${SKIP_INSTALL}" ] && apk.static add gnupg; };
# BEGIN: custom build of OpenSSL with AES wrapping enabled.
cmd_03() { [ ! "${SKIP_INSTALL}" ] && pgp_parse_openssl_latest_version; };
cmd_04() { [ ! "${SKIP_INSTALL}" ] && pgp_download_and_extract_openssl_latest_version; };
cmd_05() { [ ! "${SKIP_INSTALL}" ] && pgp_enable_aes_wrapping_in_openssl; };
cmd_06() { [ ! "${SKIP_INSTALL}" ] && pgp_compile_patched_openssl; };
cmd_07() { [ ! "${SKIP_INSTALL}" ] && pgp_create_openssl_run_script; };
cmd_08() { [ ! "${SKIP_INSTALL}" ] && pgp_create_openssl_alias; };
# END: custom build of OpenSSL with AES wrapping enabled.
cmd_09() { [ ! "${SKIP_INSTALL}" ] && mkdir -pm 0700 /pgp/keys; };
cmd_10() { [ ! "${SKIP_INSTALL}" ] && mkdir -m 0700 /pgp/phrases; };
# TODO: Write pass phrases to pipe in dedicated function.
cmd_11() { [ ! "${SKIP_INSTALL}" ] && pgp_generate_and_run_batch "$(pgp_generate_pass_phrases)"; };
cmd_12() { [ ! "${SKIP_INSTALL}" ] && pgp_export_keys; };
# Generate payload_aes.
# TODO: Write payload_aes to pipe in dedicated function.
cmd_13() { [ ! "${SKIP_INSTALL}" ] && OPENSSL_V111 rand -out payload_aes 32; };
# Wrap sensitive data in payload_aes. (data*)
# TODO: pipe in "data_raw".
# TODO: persist "data_wrapped".
cmd_14() { [ ! "${SKIP_INSTALL}" ] && OPENSSL_V111 enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < payload_aes) -iv A65959A6 -in data_raw -out data_wrapped; };
# Generate ephemeral_aes.
# TODO: Write "ephemeral_aes" to pipe in dedicated function.
cmd_15() { [ ! "${SKIP_INSTALL}" ] && OPENSSL_V111 rand -out ephemeral_aes 32; };
# Wrap payload_aes in ephemeral_aes. (payload*)
# TODO: pipe in "payload_aes".
# TODO: write "payload_wrapped" to pipe?
cmd_16() { [ ! "${SKIP_INSTALL}" ] && OPENSSL_V111 enc -id-aes256-wrap-pad -K $(hexdump -v -e '/1 "%02X"' < ephemeral_aes) -iv A65959A6 -in payload_aes -out payload_wrapped; };
# Generate RSA key pair.
# TODO: write keys to pipe in dedicated function(s).
# TODO: perist "public.key".
cmd_17() { [ ! "${SKIP_INSTALL}" ] && OPENSSL_V111 genpkey -out private.pem -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096; };
cmd_18() { [ ! "${SKIP_INSTALL}" ] && OPENSSL_V111 rsa -in private.pem -inform PEM -out public.pem -outform PEM -pubout; };
# Wrap ephemeral_aes in public.key. (ephemeral*)
# TODO: write "ephemeral_wrapped" to pipe in dedicated function.
cmd_19() { [ ! "${SKIP_INSTALL}" ] && OPENSSL_V111 pkeyutl -encrypt -in ephemeral_aes -out ephemeral_wrapped -pubin -inkey public.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha1 -pkeyopt rsa_mgf1_md:sha1; };
# Concatenate ephemeral*, payload* into single file. (rsa_aes_wrapped)
# TODO: pipe "ephemeral_wrapped", "payload_wrapped" into file.
# Resulting Files:
# - data*  the actual data that was encrypted.
# - public.key  the key used to decrypt ephemeral* and payload*.
# - rsa_aes_wrapped  the file containing ephemeral* and payload*.

# Use payload to encrypt pass phrases.
cmd_08() { [ ! "$(ls -A /pgp/keys/ 2>/dev/null)" ] && pgp_encrypt_pass_phrases; };
cmd_len() { echo 08; };