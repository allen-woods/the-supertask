init_01() { [ "$(cat < /etc/apk/repositories | grep -o 'latest-stable' | echo)" == "" ] && sed -ie 's/v[[:digit:]]\..*\//latest-stable\//g' /etc/apk/repositories && bump_cmd; };
init_02() { apk update && bump_cmd; };
init_03() { apk add busybox-static && bump_cmd; };
init_04() { apk add apk-tools-static && bump_cmd; };
init_05() { apk.static upgrade --no-self-upgrade --available --simulate && bump_cmd; };
init_06() { apk.static upgrade --no-self-upgrade --available && bump_cmd; };
init_len() { echo 06; };

bump_cmd() { INSTALL_CMD_COMPLETED=$(($INSTALL_CMD_COMPLETED + 1)); echo "Bumped to ${INSTALL_CMD_COMPLETED}."; };