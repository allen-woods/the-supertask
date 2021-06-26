#!/bin/sh
utf8_char_file() {
  local UTF8_START=33
  local UTF8_I=33
  local UTF8_END=195103
  local UTF8_FONT=
  local LAST_FONT=

  # Install ImageMagick if Not Found.
  [ ! -z "$( ( convert ) 2>&1 | grep -o "not found" )" ] && \
  [ ! -z "$( ( compare ) 2>&1 | grep -o "not found" )" ] && \
  apk update && \
  apk --no-cache add imagemagick=7.0.10.57-r0

  # Generate Destination Folder if Not Found.
  if [ ! -d $HOME/.aes_rsa_utf8_support ]; then
    mkdir -p $HOME/.aes_rsa_utf8_support/compare
    mkdir $HOME/.aes_rsa_utf8_support/convert
    mkdir $HOME/.aes_rsa_utf8_support/character_set
  fi

  # Install Fonts if Not Found.
  [ ! -d /usr/share/fonts/noto ] && \
  apk update && \
  apk --no-cache add \
  font-noto-all=0_git20190623-r2 \
  font-noto-cjk=0_git20181130-r1 \
  font-noto-cjk-extra=0_git20181130-r1 \
  font-noto-emoji=0_git20200916-r1

  # We use this variable to control line length inside "char_file.utf8".
  local CHAR_COUNT=0

  # Generate Character File Containing Printable, Unique Glyphs.
  echo "Generating: UTF-8 Character File...    (This will take a long time)"
  while [ $UTF8_I -ge $UTF8_START ] && [ $UTF8_I -le $UTF8_END ]; do
    # We use this variable to latch creation of PNG files used with "compare" utility.
    LAST_FONT=${UTF8_FONT}
    local UTF8_COMPARE=1
    local UTF8_PRINT=1

    # We must identify the correct font to use based on the value of UTF8_I.
    if [ $UTF8_I -ge 0 ] && [ $UTF8_I -le 879 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 127 && $UTF8_I -le 159 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi

      # Allow Non-Breaking Space to Override Image Comparison.
      [ $UTF8_I -eq 160 ] && UTF8_COMPARE=0
      # (This character would otherwise return a false positive that
      # would cause it to be skipped.)
    fi
    if [ $UTF8_I -ge 880 ] && [ $UTF8_I -le 1023 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Coptic-Regular
    fi
    if [ $UTF8_I -ge 1024 ] && [ $UTF8_I -le 1279 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 1280 ] && [ $UTF8_I -le 1327 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 1328 ] && [ $UTF8_I -le 1423 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Armenian-Regular
    fi
    if [ $UTF8_I -ge 1424 ] && [ $UTF8_I -le 1535 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Hebrew-Regular
    fi
    if [ $UTF8_I -ge 1536 ] && [ $UTF8_I -le 1791 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Arabic-Regular
    fi
    if [ $UTF8_I -ge 1792 ] && [ $UTF8_I -le 1871 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Syriac-Regular
    fi
    if [ $UTF8_I -ge 1872 ] && [ $UTF8_I -le 1919 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Arabic-Regular
    fi
    if [ $UTF8_I -ge 1920 ] && [ $UTF8_I -le 1983 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Thaana-Regular
    fi
    if [ $UTF8_I -ge 1984 ] && [ $UTF8_I -le 2047 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-NKo-Regular
    fi
    if [ $UTF8_I -ge 2048 ] && [ $UTF8_I -le 2111 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Samaritan-Regular
    fi
    if [ $UTF8_I -ge 2112 ] && [ $UTF8_I -le 2143 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mandaic-Regular
    fi
    if [ $UTF8_I -ge 2144 ] && [ $UTF8_I -le 2159 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Syriac-Regular
    fi
    if [ $UTF8_I -ge 2208 ] && [ $UTF8_I -le 2303 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Arabic-Regular
      # "Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 2260 ] || \
      [[ $UTF8_I -ge 2266 && $UTF8_I -le 2271 ]] || \
      [ $UTF8_I -eq 2274 ] || \
      [ $UTF8_I -eq 2298 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 2304 ] && [ $UTF8_I -le 2431 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Devanagari-Regular
    fi
    if [ $UTF8_I -ge 2432 ] && [ $UTF8_I -le 2559 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Bengali-Regular
    fi
    if [ $UTF8_I -ge 2560 ] && [ $UTF8_I -le 2687 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Gurmukhi
    fi
    if [ $UTF8_I -ge 2688 ] && [ $UTF8_I -le 2815 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Gujarati
    fi
    if [ $UTF8_I -ge 2816 ] && [ $UTF8_I -le 2943 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Oriya
    fi
    if [ $UTF8_I -ge 2944 ] && [ $UTF8_I -le 3071 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tamil-Regular
    fi
    if [ $UTF8_I -ge 3072 ] && [ $UTF8_I -le 3199 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Telugu
    fi
    if [ $UTF8_I -ge 3200 ] && [ $UTF8_I -le 3327 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Kannada-Regular
    fi
    if [ $UTF8_I -ge 3328 ] && [ $UTF8_I -le 3455 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Malayalam-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 3407 && $UTF8_I -le 3414 ]] || \
      [[ $UTF8_I -ge 3416 && $UTF8_I -le 3422 ]] || \
      [[ $UTF8_I -ge 3446 && $UTF8_I -le 3448 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 3456 ] && [ $UTF8_I -le 3583 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Sinhala-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 3558 && $UTF8_I -le 3567 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 3584 ] && [ $UTF8_I -le 3711 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Thai-Regular
    fi
    if [ $UTF8_I -ge 3712 ] && [ $UTF8_I -le 3839 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Lao-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 3806 && $UTF8_I -le 3807 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 3840 ] && [ $UTF8_I -le 4095 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tibetan
      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 3980 ] || \
      [[ $UTF8_I -ge 4057 && $UTF8_I -le 4058 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 4096 ] && [ $UTF8_I -le 4255 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Myanmar-Regular
    fi
    if [ $UTF8_I -ge 4256 ] && [ $UTF8_I -le 4351 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Georgian-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 4295 && $UTF8_I -le 4301 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 4352 ] && [ $UTF8_I -le 4607 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-KR
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 4442 && $UTF8_I -le 4446 ]] || \
      [[ $UTF8_I -ge 4515 && $UTF8_I -le 4519 ]] || \
      [[ $UTF8_I -ge 4602 && $UTF8_I -le 4607 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 4608 ] && [ $UTF8_I -le 4991 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Ethiopic-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 4957 && $UTF8_I -le 4958 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 4992 ] && [ $UTF8_I -le 5023 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Ethiopic-Regular
    fi
    if [ $UTF8_I -ge 5024 ] && [ $UTF8_I -le 5119 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Cherokee-Regular
    fi
    if [ $UTF8_I -ge 5120 ] && [ $UTF8_I -le 5759 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Canadian-Aboriginal-Regular
      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 5120 ] || \
      [[ $UTF8_I -ge 5751 && $UTF8_I -le 5759 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 5760 ] && [ $UTF8_I -le 5791 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Ogham-Regular
    fi
    if [ $UTF8_I -ge 5792 ] && [ $UTF8_I -le 5887 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Runic-Regular
    fi
    if [ $UTF8_I -ge 5888 ] && [ $UTF8_I -le 5919 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tagalog-Regular
    fi
    if [ $UTF8_I -ge 5920 ] && [ $UTF8_I -le 5951 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Hanunoo-Regular
    fi
    if [ $UTF8_I -ge 5952 ] && [ $UTF8_I -le 5983 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Buhid-Regular
    fi
    if [ $UTF8_I -ge 5984 ] && [ $UTF8_I -le 6015 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tagbanwa-Regular
    fi
    if [ $UTF8_I -ge 6016 ] && [ $UTF8_I -le 6143 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Khmer-Regular
    fi
    if [ $UTF8_I -ge 6144 ] && [ $UTF8_I -le 6319 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mongolian
    fi
    if [ $UTF8_I -ge 6320 ] && [ $UTF8_I -le 6399 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Canadian-Aboriginal-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 6320 && $UTF8_I -le 6389 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 6400 ] && [ $UTF8_I -le 6479 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Limbu-Regular
    fi
    if [ $UTF8_I -ge 6480 ] && [ $UTF8_I -le 6527 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tai-Le-Regular
    fi
    if [ $UTF8_I -ge 6528 ] && [ $UTF8_I -le 6623 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-New-Tai-Lue-Regular
    fi
    if [ $UTF8_I -ge 6624 ] && [ $UTF8_I -le 6655 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Khmer-Regular
    fi
    if [ $UTF8_I -ge 6656 ] && [ $UTF8_I -le 6687 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Buginese-Regular
    fi
    if [ $UTF8_I -ge 6688 ] && [ $UTF8_I -le 6831 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tai-Tham
    fi
    # if [ $UTF8_I -ge 6832 ] && [ $UTF8_I -le 6911 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Combining-Diacritical-Marks-Extended-Regular
    # fi
    if [ $UTF8_I -ge 6912 ] && [ $UTF8_I -le 7039 ]; then
      # Ok
      UTF8_FONT=Noto-Serif-Balinese-Regular
    fi
    if [ $UTF8_I -ge 7040 ] && [ $UTF8_I -le 7103 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Sundanese-Regular
    fi
    if [ $UTF8_I -ge 7104 ] && [ $UTF8_I -le 7167 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Batak-Regular
    fi
    if [ $UTF8_I -ge 7168 ] && [ $UTF8_I -le 7247 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Lepcha-Regular
    fi
    if [ $UTF8_I -ge 7248 ] && [ $UTF8_I -le 7295 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Ol-Chiki-Regular
    fi
    if [ $UTF8_I -ge 7296 ] && [ $UTF8_I -le 7311 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 7312 ] && [ $UTF8_I -le 7359 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Georgian-Regular
    fi
    if [ $UTF8_I -ge 7360 ] && [ $UTF8_I -le 7375 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Sundanese-Regular
    fi
    if [ $UTF8_I -ge 7376 ] && [ $UTF8_I -le 7423 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Devanagari-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 7380 && $UTF8_I -le 7384 ]] || \
      [ $UTF8_I -eq 7387 ] || \
      [[ $UTF8_I -ge 7393 && $UTF8_I -le 7409 ]] || \
      [ $UTF8_I -eq 7414 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 7424 ] && [ $UTF8_I -le 8399 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 8400 ] && [ $UTF8_I -le 8447 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols-Regular
      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 8418 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 8448 ] && [ $UTF8_I -le 8527 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 8528 ] && [ $UTF8_I -le 8703 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 8583 && $UTF8_I -le 8584 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 8704 ] && [ $UTF8_I -le 9215 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 9216 ] && [ $UTF8_I -le 9311 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
    fi
    if [ $UTF8_I -ge 9312 ] && [ $UTF8_I -le 9471 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols-Regular
    fi
    if [ $UTF8_I -ge 9472 ] && [ $UTF8_I -le 9727 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 9728 ] && [ $UTF8_I -le 10175 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols-Regular
      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 9885 ] || \
      [[ $UTF8_I -ge 9907 && $UTF8_I -le 9916 ]] || \
      [[ $UTF8_I -ge 9955 && $UTF8_I -le 9960 ]] || \
      [[ $UTF8_I -ge 9963 && $UTF8_I -le 9967 ]] || \
      [ $UTF8_I -eq 9974 ] || \
      [[ $UTF8_I -ge 9979 && $UTF8_I -le 9980 ]] || \
      [[ $UTF8_I -ge 9982 && $UTF8_I -le 9983 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    # if [ $UTF8_I -ge 10176 ] && [ $UTF8_I -le 10223 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Miscellaneous-Mathematical-Symbols-A-Regular
    # fi
    # if [ $UTF8_I -ge 10224 ] && [ $UTF8_I -le 10239 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Supplemental-Arrows-A-Regular
    # fi
    if [ $UTF8_I -ge 10240 ] && [ $UTF8_I -le 10495 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
    fi
    # if [ $UTF8_I -ge 10496 ] && [ $UTF8_I -le 10623 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Supplemental-Arrows-B-Regular
    # fi
    # if [ $UTF8_I -ge 10624 ] && [ $UTF8_I -le 10751 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Miscellaneous-Mathematical-Symbols-B-Regular
    # fi
    # if [ $UTF8_I -ge 10752 ] && [ $UTF8_I -le 11007 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Supplemental-Mathematical-Operators-Regular
    # fi
    if [ $UTF8_I -ge 11008 ] && [ $UTF8_I -le 11263 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 11085 && $UTF8_I -le 11087 ]] || \
      [[ $UTF8_I -ge 11094 && $UTF8_I -le 11095 ]] || \
      [[ $UTF8_I -ge 11097 && $UTF8_I -le 11103 ]] || \
      [[ $UTF8_I -ge 11110 && $UTF8_I -le 11135 ]] || \
      [[ $UTF8_I -ge 11140 && $UTF8_I -le 11151 ]] || \
      [[ $UTF8_I -ge 11154 && $UTF8_I -le 11156 ]] || \
      [[ $UTF8_I -ge 11160 && $UTF8_I -le 11247 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 11264 ] && [ $UTF8_I -le 11359 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Glagolitic-Regular
    fi
    if [ $UTF8_I -ge 11360 ] && [ $UTF8_I -le 11391 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 11392 ] && [ $UTF8_I -le 11519 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Coptic-Regular
    fi
    if [ $UTF8_I -ge 11520 ] && [ $UTF8_I -le 11567 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Georgian-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 11520 && $UTF8_I -le 11565 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 11568 ] && [ $UTF8_I -le 11647 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tifinagh-Regular
    fi
    if [ $UTF8_I -ge 11648 ] && [ $UTF8_I -le 11743 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Ethiopic-Regular
    fi
    if [ $UTF8_I -ge 11744 ] && [ $UTF8_I -le 11775 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 11776 ] && [ $UTF8_I -le 11903 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 11843 && $UTF8_I -le 11844 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 11904 ] && [ $UTF8_I -le 12031 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 12032 ] && [ $UTF8_I -le 12255 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 12272 ] && [ $UTF8_I -le 12287 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 12288 ] && [ $UTF8_I -le 12351 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 12352 ] && [ $UTF8_I -le 12447 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-JP
    fi
    if [ $UTF8_I -ge 12448 ] && [ $UTF8_I -le 12543 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-JP
    fi
    if [ $UTF8_I -ge 12544 ] && [ $UTF8_I -le 12591 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 12589 && $UTF8_I -le 12591 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 12592 ] && [ $UTF8_I -le 12687 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-KR
    fi
    if [ $UTF8_I -ge 12688 ] && [ $UTF8_I -le 12703 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-JP
    fi
    if [ $UTF8_I -ge 12704 ] && [ $UTF8_I -le 12783 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 12728 && $UTF8_I -le 12731 ]] || \
      [[ $UTF8_I -ge 12752 && $UTF8_I -le 12771 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 12784 ] && [ $UTF8_I -le 12799 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-JP
    fi
    if [ $UTF8_I -ge 12800 ] && [ $UTF8_I -le 19903 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 12829 && $UTF8_I -le 12830 ]] || \
      [[ $UTF8_I -ge 12924 && $UTF8_I -le 12926 ]] || \
      [[ $UTF8_I -ge 13004 && $UTF8_I -le 13007 ]] || \
      [[ $UTF8_I -ge 13175 && $UTF8_I -le 13178 ]] || \
      [[ $UTF8_I -ge 13278 && $UTF8_I -le 13279 ]] || \
      [ $UTF8_I -eq 13311 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 19904 ] && [ $UTF8_I -le 19967 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
    fi
    if [ $UTF8_I -ge 19968 ] && [ $UTF8_I -le 40959 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 40899 ] || \
      [ $UTF8_I -eq 40901 ] || \
      [[ $UTF8_I -ge 40913 && $UTF8_I -le 40943 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 40960 ] && [ $UTF8_I -le 42191 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Yi-Regular
    fi
    if [ $UTF8_I -ge 42192 ] && [ $UTF8_I -le 42239 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Lisu-Regular
    fi
    if [ $UTF8_I -ge 42240 ] && [ $UTF8_I -le 42559 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Vai-Regular
    fi
    if [ $UTF8_I -ge 42560 ] && [ $UTF8_I -le 42655 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 42656 ] && [ $UTF8_I -le 42751 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Bamum-Regular
    fi
    if [ $UTF8_I -ge 42752 ] && [ $UTF8_I -le 43007 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 43008 ] && [ $UTF8_I -le 43055 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Syloti-Nagri-Regular
    fi
    if [ $UTF8_I -ge 43056 ] && [ $UTF8_I -le 43071 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Devanagari-Regular
    fi
    if [ $UTF8_I -ge 43072 ] && [ $UTF8_I -le 43135 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-PhagsPa-Regular
    fi
    if [ $UTF8_I -ge 43136 ] && [ $UTF8_I -le 43231 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Saurashtra-Regular
    fi
    if [ $UTF8_I -ge 43232 ] && [ $UTF8_I -le 43263 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Devanagari-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 43242 && $UTF8_I -le 43261 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 43264 ] && [ $UTF8_I -le 43311 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Kayah-Li-Regular
    fi
    if [ $UTF8_I -ge 43312 ] && [ $UTF8_I -le 43359 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Rejang-Regular
    fi
    if [ $UTF8_I -ge 43360 ] && [ $UTF8_I -le 43391 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-KR
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 43360 && $UTF8_I -le 43388 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 43392 ] && [ $UTF8_I -le 43487 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Javanese-Regular
    fi
    if [ $UTF8_I -ge 43488 ] && [ $UTF8_I -le 43519 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Myanmar-Regular
    fi
    if [ $UTF8_I -ge 43520 ] && [ $UTF8_I -le 43615 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Cham-Regular
    fi
    if [ $UTF8_I -ge 43616 ] && [ $UTF8_I -le 43647 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Myanmar-Regular
    fi
    if [ $UTF8_I -ge 43648 ] && [ $UTF8_I -le 43743 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tai-Viet-Regular
    fi
    if [ $UTF8_I -ge 43744 ] && [ $UTF8_I -le 43775 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Meetei-Mayek-Regular
    fi
    if [ $UTF8_I -ge 43776 ] && [ $UTF8_I -le 43823 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Ethiopic-Regular
    fi
    if [ $UTF8_I -ge 43824 ] && [ $UTF8_I -le 43887 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 43888 ] && [ $UTF8_I -le 43967 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Cherokee-Regular
    fi
    if [ $UTF8_I -ge 43968 ] && [ $UTF8_I -le 44031 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Meetei-Mayek-Regular
    fi
    if [ $UTF8_I -ge 44032 ] && [ $UTF8_I -le 55295 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-KR
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 55216 && $UTF8_I -le 55291 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    # if [ $UTF8_I -ge 55296 ] && [ $UTF8_I -le 56191 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-High-Surrogates-Regular
    # fi
    # if [ $UTF8_I -ge 56192 ] && [ $UTF8_I -le 56319 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-High-Private-Use-Surrogates-Regular
    # fi
    # if [ $UTF8_I -ge 56320 ] && [ $UTF8_I -le 57343 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Low-Surrogates-Regular
    # fi
    # if [ $UTF8_I -ge 57344 ] && [ $UTF8_I -le 63743 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Private-Use-Area-Regular
    # fi
    if [[ $UTF8_I -ge 55296 && $UTF8_I -le 63743 ]]; then
      # Prevent "no glyph" leaks:
      UTF8_COMPARE=0
      UTF8_PRINT=0
    fi
    if [ $UTF8_I -ge 63744 ] && [ $UTF8_I -le 64255 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-JP
    fi
    if [ $UTF8_I -ge 64256 ] && [ $UTF8_I -le 64335 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Hebrew-Regular
    fi
    if [ $UTF8_I -ge 64336 ] && [ $UTF8_I -le 65023 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Arabic-Regular
    fi
    if [ $UTF8_I -ge 65024 ] && [ $UTF8_I -le 65039 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 65040 ] && [ $UTF8_I -le 65055 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 65056 ] && [ $UTF8_I -le 65071 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Regular
    fi
    if [ $UTF8_I -ge 65072 ] && [ $UTF8_I -le 65135 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 65136 ] && [ $UTF8_I -le 65279 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Arabic-Regular
    fi
    if [ $UTF8_I -ge 65280 ] && [ $UTF8_I -le 65519 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
    fi
    if [ $UTF8_I -ge 65520 ] && [ $UTF8_I -le 65535 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
    fi
    if [ $UTF8_I -ge 65536 ] && [ $UTF8_I -le 65855 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Linear-B-Regular
    fi
    if [ $UTF8_I -ge 65856 ] && [ $UTF8_I -le 66047 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 65860 && $UTF8_I -le 65861 ]] || \
      [[ $UTF8_I -ge 65910 && $UTF8_I -le 65912 ]] || \
      [ $UTF8_I -eq 65923 ] || \
      [[ $UTF8_I -ge 65927 && $UTF8_I -le 65929 ]] || \
      [[ $UTF8_I -ge 65931 && $UTF8_I -le 65934 ]] || \
      [[ $UTF8_I -ge 65952 && $UTF8_I -le 66045 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 66176 ] && [ $UTF8_I -le 66207 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Lycian-Regular
    fi
    if [ $UTF8_I -ge 66208 ] && [ $UTF8_I -le 66271 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Carian-Regular
    fi
    if [ $UTF8_I -ge 66272 ] && [ $UTF8_I -le 66303 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Coptic-Regular
    fi
    if [ $UTF8_I -ge 66304 ] && [ $UTF8_I -le 66351 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Old-Italic-Regular
    fi
    if [ $UTF8_I -ge 66352 ] && [ $UTF8_I -le 66383 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Gothic-Regular
    fi
    if [ $UTF8_I -ge 66384 ] && [ $UTF8_I -le 66431 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Old-Permic-Regular
    fi
    if [ $UTF8_I -ge 66432 ] && [ $UTF8_I -le 66463 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Ugaritic-Regular
    fi
    if [ $UTF8_I -ge 66464 ] && [ $UTF8_I -le 66527 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Old-Persian-Regular
    fi
    if [ $UTF8_I -ge 66560 ] && [ $UTF8_I -le 66639 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Deseret-Regular
    fi
    if [ $UTF8_I -ge 66640 ] && [ $UTF8_I -le 66687 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Shavian-Regular
    fi
    if [ $UTF8_I -ge 66688 ] && [ $UTF8_I -le 66735 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Osmanya-Regular
    fi
    if [ $UTF8_I -ge 66736 ] && [ $UTF8_I -le 66815 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Osage-Regular
    fi
    if [ $UTF8_I -ge 66816 ] && [ $UTF8_I -le 66863 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Elbasan-Regular
    fi
    if [ $UTF8_I -ge 66864 ] && [ $UTF8_I -le 66927 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Caucasian-Albanian-Regular
    fi
    if [ $UTF8_I -ge 67072 ] && [ $UTF8_I -le 67455 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Linear-A-Regular
    fi
    if [ $UTF8_I -ge 67584 ] && [ $UTF8_I -le 67647 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Cypriot-Regular
    fi
    if [ $UTF8_I -ge 67648 ] && [ $UTF8_I -le 67679 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Imperial-Aramaic-Regular
    fi
    if [ $UTF8_I -ge 67680 ] && [ $UTF8_I -le 67711 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Palmyrene-Regular
    fi
    if [ $UTF8_I -ge 67712 ] && [ $UTF8_I -le 67759 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Nabataean-Regular
    fi
    if [ $UTF8_I -ge 67808 ] && [ $UTF8_I -le 67839 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Hatran-Regular
    fi
    if [ $UTF8_I -ge 67840 ] && [ $UTF8_I -le 67871 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Phoenician-Regular
    fi
    if [ $UTF8_I -ge 67872 ] && [ $UTF8_I -le 67903 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Lydian-Regular
    fi
    if [ $UTF8_I -ge 67968 ] && [ $UTF8_I -le 67999 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Meroitic-Regular
    fi
    if [ $UTF8_I -ge 68000 ] && [ $UTF8_I -le 68095 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Meroitic-Regular
    fi
    if [ $UTF8_I -ge 68096 ] && [ $UTF8_I -le 68191 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Kharoshthi-Regular
    fi
    if [ $UTF8_I -ge 68192 ] && [ $UTF8_I -le 68223 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Old-South-Arabian-Regular
    fi
    if [ $UTF8_I -ge 68224 ] && [ $UTF8_I -le 68255 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Old-North-Arabian-Regular
    fi
    if [ $UTF8_I -ge 68288 ] && [ $UTF8_I -le 68351 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Manichaean-Regular
    fi
    if [ $UTF8_I -ge 68352 ] && [ $UTF8_I -le 68415 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Avestan-Regular
    fi
    if [ $UTF8_I -ge 68416 ] && [ $UTF8_I -le 68447 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Inscriptional-Parthian-Regular
    fi
    if [ $UTF8_I -ge 68448 ] && [ $UTF8_I -le 68479 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Inscriptional-Pahlavi-Regular
    fi
    if [ $UTF8_I -ge 68480 ] && [ $UTF8_I -le 68527 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Psalter-Pahlavi-Regular
    fi
    if [ $UTF8_I -ge 68608 ] && [ $UTF8_I -le 68687 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Old-Turkic-Regular
    fi
    if [ $UTF8_I -ge 68736 ] && [ $UTF8_I -le 68863 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Old-Hungarian-Regular
    fi
    if [ $UTF8_I -ge 68864 ] && [ $UTF8_I -le 68927 ]; then
      # Ok
      UTF8_FONT=Noto-Nastaliq-Urdu-Regular
    fi
    if [ $UTF8_I -ge 69216 ] && [ $UTF8_I -le 69247 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 69216 && $UTF8_I -le 69246 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    # if [ $UTF8_I -ge 69248 ] && [ $UTF8_I -le 69311 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Yezidi-Regular
    # fi
    # if [ $UTF8_I -ge 69376 ] && [ $UTF8_I -le 69423 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Old-Sogdian-Regular
    # fi
    # if [ $UTF8_I -ge 69424 ] && [ $UTF8_I -le 69487 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Sogdian-Regular
    # fi
    # if [ $UTF8_I -ge 69552 ] && [ $UTF8_I -le 69599 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Chorasmian-Regular
    # fi
    # if [ $UTF8_I -ge 69600 ] && [ $UTF8_I -le 69631 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Elymaic-Regular
    # fi
    if [ $UTF8_I -ge 69632 ] && [ $UTF8_I -le 69759 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Brahmi-Regular
    fi
    if [ $UTF8_I -ge 69760 ] && [ $UTF8_I -le 69839 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Kaithi-Regular
    fi
    if [ $UTF8_I -ge 69840 ] && [ $UTF8_I -le 69887 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Sora-Sompeng-Regular
    fi
    if [ $UTF8_I -ge 69888 ] && [ $UTF8_I -le 69967 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Chakma-Regular
    fi
    if [ $UTF8_I -ge 69968 ] && [ $UTF8_I -le 70015 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mahajani-Regular
    fi
    if [ $UTF8_I -ge 70016 ] && [ $UTF8_I -le 70111 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Sharada-Regular
    fi
    if [ $UTF8_I -ge 70112 ] && [ $UTF8_I -le 70143 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Sinhala-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 70113 && $UTF8_I -le 70132 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 70144 ] && [ $UTF8_I -le 70223 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Khojki-Regular
    fi
    if [ $UTF8_I -ge 70272 ] && [ $UTF8_I -le 70319 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Multani-Regular
    fi
    if [ $UTF8_I -ge 70320 ] && [ $UTF8_I -le 70399 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Khudawadi-Regular
    fi
    if [ $UTF8_I -ge 70400 ] && [ $UTF8_I -le 70527 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Grantha-Regular
    fi
    if [ $UTF8_I -ge 70656 ] && [ $UTF8_I -le 70783 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Newa-Regular
    fi
    if [ $UTF8_I -ge 70784 ] && [ $UTF8_I -le 70879 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tirhuta-Regular
    fi
    # if [ $UTF8_I -ge 71040 ] && [ $UTF8_I -le 71167 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Siddham-Regular
    # fi
    if [ $UTF8_I -ge 71168 ] && [ $UTF8_I -le 71263 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Modi-Regular
    fi
    if [ $UTF8_I -ge 71264 ] && [ $UTF8_I -le 71295 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mongolian
    fi
    if [ $UTF8_I -ge 71296 ] && [ $UTF8_I -le 71375 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Takri-Regular
    fi
    if [ $UTF8_I -ge 71424 ] && [ $UTF8_I -le 71487 ]; then
      # Ok
      UTF8_FONT=Noto-Serif-Ahom-Regular
    fi
    # if [ $UTF8_I -ge 71680 ] && [ $UTF8_I -le 71759 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Dogra-Regular
    # fi
    if [ $UTF8_I -ge 71840 ] && [ $UTF8_I -le 71935 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Warang-Citi-Regular
    fi
    # if [ $UTF8_I -ge 71936 ] && [ $UTF8_I -le 72031 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Dives-Akuru-Regular
    # fi
    # if [ $UTF8_I -ge 72096 ] && [ $UTF8_I -le 72191 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Nandinagari-Regular
    # fi
    # if [ $UTF8_I -ge 72192 ] && [ $UTF8_I -le 72271 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Zanabazar-Square-Regular
    # fi
    # if [ $UTF8_I -ge 72272 ] && [ $UTF8_I -le 72367 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Soyombo-Regular
    # fi
    if [ $UTF8_I -ge 72384 ] && [ $UTF8_I -le 72447 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Pau-Cin-Hau-Regular
    fi
    if [ $UTF8_I -ge 72704 ] && [ $UTF8_I -le 72815 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Bhaiksuki-Regular
    fi
    if [ $UTF8_I -ge 72816 ] && [ $UTF8_I -le 72895 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Marchen-Regular
    fi
    # if [ $UTF8_I -ge 72960 ] && [ $UTF8_I -le 73055 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Masaram-Gondi-Regular
    # fi
    # if [ $UTF8_I -ge 73056 ] && [ $UTF8_I -le 73135 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Gunjala-Gondi-Regular
    # fi
    # if [ $UTF8_I -ge 73440 ] && [ $UTF8_I -le 73471 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Makasar-Regular
    # fi
    if [ $UTF8_I -ge 73648 ] && [ $UTF8_I -le 73663 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Lisu-Regular
    fi
    if [ $UTF8_I -ge 73664 ] && [ $UTF8_I -le 73727 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Tamil-Regular
    fi
    if [ $UTF8_I -ge 73728 ] && [ $UTF8_I -le 75087 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Cuneiform-Regular
    fi
    if [ $UTF8_I -ge 77824 ] && [ $UTF8_I -le 78911 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Egyptian-Hieroglyphs-Regular
    fi
    if [ $UTF8_I -ge 82944 ] && [ $UTF8_I -le 83583 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Anatolian-Hieroglyphs-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 82944 && $UTF8_I -le 83526 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 92160 ] && [ $UTF8_I -le 92735 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Bamum-Regular
    fi
    if [ $UTF8_I -ge 92736 ] && [ $UTF8_I -le 92783 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mro-Regular
    fi
    if [ $UTF8_I -ge 92880 ] && [ $UTF8_I -le 92927 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Bassa-Vah-Regular
    fi
    if [ $UTF8_I -ge 92928 ] && [ $UTF8_I -le 93071 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Pahawh-Hmong-Regular
    fi
    # if [ $UTF8_I -ge 93760 ] && [ $UTF8_I -le 93855 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Medefaidrin-Regular
    # fi
    if [ $UTF8_I -ge 93952 ] && [ $UTF8_I -le 94111 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Miao-Regular
    fi
    # if [ $UTF8_I -ge 94176 ] && [ $UTF8_I -le 94207 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Ideographic-Symbols-and-Punctuation-Regular
    # fi
    # if [ $UTF8_I -ge 94208 ] && [ $UTF8_I -le 100351 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Tangut-Regular
    # fi
    # if [ $UTF8_I -ge 100352 ] && [ $UTF8_I -le 101119 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Tangut-Components-Regular
    # fi
    # if [ $UTF8_I -ge 101120 ] && [ $UTF8_I -le 101631 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Khitan-Small-Script-Regular
    # fi
    # if [ $UTF8_I -ge 101632 ] && [ $UTF8_I -le 101775 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Tangut-Supplement-Regular
    # fi
    # if [ $UTF8_I -ge 110592 ] && [ $UTF8_I -le 110847 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Kana-Supplement-Regular
    # fi
    # if [ $UTF8_I -ge 110848 ] && [ $UTF8_I -le 110895 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Kana-Extended-A-Regular
    # fi
    # if [ $UTF8_I -ge 110896 ] && [ $UTF8_I -le 110959 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Small-Kana-Extension-Regular
    # fi
    # if [ $UTF8_I -ge 110960 ] && [ $UTF8_I -le 111359 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Nushu-Regular
    # fi
    if [ $UTF8_I -ge 113664 ] && [ $UTF8_I -le 113823 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Duployan-Regular
    fi
    # if [ $UTF8_I -ge 113824 ] && [ $UTF8_I -le 113839 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Shorthand-Format-Controls-Regular
    # fi
    # if [ $UTF8_I -ge 118784 ] && [ $UTF8_I -le 119039 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Byzantine-Musical-Symbols-Regular
    # fi
    if [ $UTF8_I -ge 119040 ] && [ $UTF8_I -le 119295 ]; then
      # Ok
      UTF8_FONT=Noto-Music-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 119049 && $UTF8_I -le 119055 ]] || \
      [[ $UTF8_I -ge 119059 && $UTF8_I -le 119069 ]] || \
      [[ $UTF8_I -ge 119071 && $UTF8_I -le 119072 ]] || \
      [[ $UTF8_I -ge 119075 && $UTF8_I -le 119081 ]] || \
      [[ $UTF8_I -ge 119084 && $UTF8_I -le 119185 ]] || \
      [[ $UTF8_I -ge 119188 && $UTF8_I -le 119205 ]] || \
      [[ $UTF8_I -ge 119209 && $UTF8_I -le 119238 ]] || \
      [[ $UTF8_I -ge 119247 && $UTF8_I -le 119295 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 119296 ] && [ $UTF8_I -le 119375 ]; then
      # Guess
      UTF8_FONT=Noto-Music-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 119296 && $UTF8_I -le 119365 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    # if [ $UTF8_I -ge 119520 ] && [ $UTF8_I -le 119551 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Mayan-Numerals-Regular
    # fi
    if [ $UTF8_I -ge 119552 ] && [ $UTF8_I -le 119679 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
    fi
    # if [ $UTF8_I -ge 119808 ] && [ $UTF8_I -le 120831 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Mathematical-Alphanumeric-Symbols-Regular
    # fi
    # if [ $UTF8_I -ge 120832 ] && [ $UTF8_I -le 121519 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Sutton-SignWriting-Regular
    # fi
    if [ $UTF8_I -ge 122880 ] && [ $UTF8_I -le 122927 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Glagolitic-Regular
    fi
    # if [ $UTF8_I -ge 123136 ] && [ $UTF8_I -le 123215 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Nyiakeng-Puachue-Hmong-Regular
    # fi
    # if [ $UTF8_I -ge 123584 ] && [ $UTF8_I -le 123647 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Wancho-Regular
    # fi
    if [ $UTF8_I -ge 124928 ] && [ $UTF8_I -le 125151 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mende-Kikakui-Regular
    fi
    if [ $UTF8_I -ge 125184 ] && [ $UTF8_I -le 125279 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Adlam-Regular
    fi
    # if [ $UTF8_I -ge 126064 ] && [ $UTF8_I -le 126143 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Indic-Siyaq-Numbers-Regular
    # fi
    # if [ $UTF8_I -ge 126208 ] && [ $UTF8_I -le 126287 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Ottoman-Siyaq-Numbers-Regular
    # fi
    # if [ $UTF8_I -ge 126464 ] && [ $UTF8_I -le 126719 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Arabic-Mathematical-Alphabetic-Symbols-Regular
    # fi
    if [ $UTF8_I -ge 126976 ] && [ $UTF8_I -le 127135 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
    fi
    if [ $UTF8_I -ge 127136 ] && [ $UTF8_I -le 127231 ]; then
      # Confirmed Missing
      # UTF8_FONT=Noto-Sans-Playing-Cards-Regular

      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 127167 ] || \
      [[ $UTF8_I -ge 127200 && $UTF8_I -le 127221 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 127232 ] && [ $UTF8_I -le 127487 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 127274 && $UTF8_I -le 127278 ]] || \
      [[ $UTF8_I -ge 127306 && $UTF8_I -le 127310 ]] || \
      [[ $UTF8_I -ge 127370 && $UTF8_I -le 127373 ]] || \
      [[ $UTF8_I -ge 127376 && $UTF8_I -le 127487 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 127488 ] && [ $UTF8_I -le 127743 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-CJK-TC
      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 127488 ] || \
      [[ $UTF8_I -ge 127507 && $UTF8_I -le 127508 ]] || \
      [ $UTF8_I -eq 127547 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 127744 ] && [ $UTF8_I -le 128511 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 127778 && $UTF8_I -le 127779 ]] || \
      [ $UTF8_I -eq 127893 ] || \
      [ $UTF8_I -eq 127896 ] || \
      [[ $UTF8_I -ge 127900 && $UTF8_I -le 127901 ]] || \
      [[ $UTF8_I -ge 127985 && $UTF8_I -le 127986 ]] || \
      [ $UTF8_I -eq 127990 ] || \
      [ $UTF8_I -eq 128254 ] || \
      [[ $UTF8_I -ge 128318 && $UTF8_I -le 128325 ]] || \
      [[ $UTF8_I -ge 128360 && $UTF8_I -le 128366 ]] || \
      [[ $UTF8_I -ge 128369 && $UTF8_I -le 128370 ]] || \
      [[ $UTF8_I -ge 128379 && $UTF8_I -le 128390 ]] || \
      [[ $UTF8_I -ge 128392 && $UTF8_I -le 128393 ]] || \
      [[ $UTF8_I -ge 128398 && $UTF8_I -le 128399 ]] || \
      [[ $UTF8_I -ge 128401 && $UTF8_I -le 128419 ]] || \
      [[ $UTF8_I -ge 128422 && $UTF8_I -le 128423 ]] || \
      [[ $UTF8_I -ge 128425 && $UTF8_I -le 128432 ]] || \
      [[ $UTF8_I -ge 128435 && $UTF8_I -le 128443 ]] || \
      [[ $UTF8_I -ge 128445 && $UTF8_I -le 128449 ]] || \
      [[ $UTF8_I -ge 128453 && $UTF8_I -le 128464 ]] || \
      [[ $UTF8_I -ge 128468 && $UTF8_I -le 128475 ]] || \
      [[ $UTF8_I -ge 128479 && $UTF8_I -le 128480 ]] || \
      [ $UTF8_I -eq 128482 ] || \
      [[ $UTF8_I -ge 128484 && $UTF8_I -le 128487 ]] || \
      [[ $UTF8_I -ge 128489 && $UTF8_I -le 128494 ]] || \
      [[ $UTF8_I -ge 128496 && $UTF8_I -le 128498 ]] || \
      [[ $UTF8_I -ge 128500 && $UTF8_I -le 128505 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 128512 ] && [ $UTF8_I -le 128591 ]; then
      # Ok
      UTF8_FONT=Noto-Emoji
    fi
    # if [ $UTF8_I -ge 128592 ] && [ $UTF8_I -le 128639 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Ornamental-Dingbats-Regular
    # fi
    if [ $UTF8_I -ge 128640 ] && [ $UTF8_I -le 128767 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols2-Regular
      # Prevent "no glyph" leaks:
      if [[ $UTF8_I -ge 128710 && $UTF8_I -le 128714 ]] || \
      [[ $UTF8_I -ge 128742 && $UTF8_I -le 128744 ]] || \
      [ $UTF8_I -eq 128746 ] || \
      [[ $UTF8_I -ge 128753 && $UTF8_I -le 128754 ]]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 128768 ] && [ $UTF8_I -le 128895 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Symbols-Regular
    fi
    # if [ $UTF8_I -ge 128896 ] && [ $UTF8_I -le 129023 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Geometric-Shapes-Extended-Regular
    # fi
    # if [ $UTF8_I -ge 129024 ] && [ $UTF8_I -le 129279 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Supplemental-Arrows-C-Regular
    # fi
    # if [ $UTF8_I -ge 129280 ] && [ $UTF8_I -le 129535 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Supplemental-Symbols-and-Pictographs-Regular
    # fi
    # if [ $UTF8_I -ge 129536 ] && [ $UTF8_I -le 129647 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Chess-Symbols-Regular
    # fi
    # if [ $UTF8_I -ge 129648 ] && [ $UTF8_I -le 129791 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Symbols-and-Pictographs-Extended-A-Regular
    # fi
    # if [ $UTF8_I -ge 129792 ] && [ $UTF8_I -le 130047 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-Symbols-for-Legacy-Computing-Regular
    # fi
    # if [ $UTF8_I -ge 131072 ] && [ $UTF8_I -le 173791 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-CJK-Unified-Ideographs-Extension-B-Regular
    # fi
    # if [ $UTF8_I -ge 173824 ] && [ $UTF8_I -le 177983 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-CJK-Unified-Ideographs-Extension-C-Regular
    # fi
    if [ $UTF8_I -ge 177984 ] && [ $UTF8_I -le 178207 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mono-CJK-TC
      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 178167 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 178208 ] && [ $UTF8_I -le 183983 ]; then
      # Confirmed Missing
      # UTF8_FONT=Noto-Sans-CJK-Unified-Ideographs-Extension-E-Regular

      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 180501 ] || \
      [ $UTF8_I -eq 181126 ] || \
      [ $UTF8_I -eq 182227 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 183984 ] && [ $UTF8_I -le 191471 ]; then
      # Confirmed Missing
      # UTF8_FONT=Noto-Sans-CJK-Unified-Ideographs-Extension-F-Regular

      # Prevent "no glyph" leaks:
      if [ $UTF8_I -eq 188436 ]; then
        UTF8_COMPARE=0
        UTF8_PRINT=0
      fi
    fi
    if [ $UTF8_I -ge 194560 ] && [ $UTF8_I -le 195103 ]; then
      # Ok
      UTF8_FONT=Noto-Sans-Mono-CJK-TC
    fi
    # if [ $UTF8_I -ge 196608 ] && [ $UTF8_I -le 201551 ]; then
    #   # Confirmed Missing
    #   UTF8_FONT=Noto-Sans-CJK-Unified-Ideographs-Extension-G-Regular
    # fi

    if [ "${LAST_FONT}" != "${UTF8_FONT}" ]; then
      # Render Guaranteed Non-printable Character.
      printf '%s' "$( utf8_char U+F040F )" | convert \
        -encoding Unicode \
        -background white \
        -fill black \
        -font ${UTF8_FONT} \
        -pointsize 24 \
        label:@- \
        png:$HOME/.aes_rsa_utf8_support/compare/no_print.png

      # Render Unknown Glyph Replacement Character ([?]).
      printf '%s' "$( utf8_char U+FFFD )" | convert \
        -encoding Unicode \
        -background white \
        -fill black \
        -font ${UTF8_FONT} \
        -pointsize 24 \
        label:@- \
        png:$HOME/.aes_rsa_utf8_support/compare/no_glyph.png
    fi

    local CHAR_I="$( utf8_char ${UTF8_I} )"

    if [ $UTF8_COMPARE -eq 1 ]; then
      if [ ! -z "${CHAR_I}" ]; then
        # Render the Character to be Compared.
        printf '%s' "${CHAR_I}" | convert \
          -encoding Unicode \
          -background white \
          -fill black \
          -font ${UTF8_FONT} \
          -pointsize 24 \
          label:@- \
          png:$HOME/.aes_rsa_utf8_support/convert/check.png
        
        local IS_UNPRINTABLE="$( \
          ( \
            compare \
            -metric MAE \
            $HOME/.aes_rsa_utf8_support/convert/check.png \
            $HOME/.aes_rsa_utf8_support/compare/no_print.png  null: \
          ) 2>&1 \
        )"
        local IS_UNKNOWN="$( \
          ( \
            compare \
            -metric MAE \
            $HOME/.aes_rsa_utf8_support/convert/check.png \
            $HOME/.aes_rsa_utf8_support/compare/no_glyph.png  null: \
          ) 2>&1 \
        )"
        if [ "${IS_UNPRINTABLE}" = "0 (0)" ] || [ "${IS_UNKNOWN}" = "0 (0)" ]; then
          UTF8_PRINT=0
        fi
      fi
    fi

    if [ -z "${CHAR_I}" ] && [ $UTF8_PRINT -eq 1 ]; then
      # Prevent "no glyph" leaks:
      UTF8_PRINT=0
    fi

    if [ $UTF8_PRINT -eq 1 ]; then
      if [ $CHAR_COUNT -eq 255 ]; then
        printf '%s\n' "${CHAR_I}" >> $HOME/.aes_rsa_utf8_support/character_set/char_file.utf8
        CHAR_COUNT=0
      else
        printf '%s' "${CHAR_I}" >> $HOME/.aes_rsa_utf8_support/character_set/char_file.utf8
        CHAR_COUNT=$(($CHAR_COUNT + 1))
      fi

      local UTF8_NL=
      [ $(($UTF8_I % 8)) -eq 0 ] && UTF8_NL=" " || UTF8_NL=" -n "

      # Give the operator feedback while they wait. (Optional)
      # echo -e${UTF8_NL}"\033[0;34m\033[40m $( printf '%06d' "${UTF8_I}" ) \033[1;33m\033[40m: ${CHAR_I}  \033[0;37m\033[47m \033[0m"
    fi

    UTF8_I=$(($UTF8_I + 1))
  done
  echo ""
  echo "DONE: UTF-8 Character File Generated."
  rm -f $HOME/.aes_rsa_utf8_support/convert/check.png
}