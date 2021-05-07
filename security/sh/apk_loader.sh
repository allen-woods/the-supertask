#!/bin/sh

apk_loader() {
  local APK_FLAGS=
  local APK_NOT_FOUND='No such file or directory'
  # Update the repositories' package availability information.
  apk ${APK_FLAGS} update
  # Iterate across incoming arguments.
  for ARG in "${@}"; do
    # If the argument is an integer, use it to set APK_FLAGS.
    if [ -z "$( echo -n ${ARG} | sed 's/[0-9]\{1,\}//g' )" ]; then
      [ $ARG -eq 0 ] && [ -z "${APK_FLAGS}" ] && APK_FLAGS='--quiet --no-progress'
      [ $ARG -eq 2 ] && [ -z "${APK_FLAGS}" ] && APK_FLAGS='--verbose'
    else
      # Extract PKG_NAME from the version string argument.
      local PKG_NAME=$( \
        echo -n ${ARG} | \
        sed "s#^\([a-z-]\{3,\}\)>.*$#\1#g" \
      )
      # If PKG_NAME is not already installed...
      if [ ! -z "$( apk info ${PKG_NAME} | grep -o ${APK_NOT_FOUND} )" ]; then
        # Add it using 'apk' if it is a static tool, or
        # Add it using 'apk.static' if it is not a static tool.
        [ ! -z "$( echo -n ${PKG_NAME} | grep -o 'static' )" ] && \
        apk ${APK_FLAGS} --no-cache add "${ARG}" || \
        apk.static ${APK_FLAGS} --no-cache add "${ARG}"
      fi
    fi
  done
  # Upgrade the repositories to permit packages to install latest versions.
  apk.static ${APK_FLAGS} upgrade
}