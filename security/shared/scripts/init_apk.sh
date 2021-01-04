init_01() { [ "$(cat < /etc/apk/repositories | grep -o 'latest-stable' | echo)" == "" ] && sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories
}
init_02() { apk update
}
init_03() { apk add busybox-static
}
init_04() { apk add apk-tools-static
}
init_05() { apk.static upgrade --no-self-upgrade --available --simulate
}
init_06() { apk.static upgrade --no-self-upgrade --available
}
init_len() { echo 06
}