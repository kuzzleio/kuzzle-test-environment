#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

# install debian/ubuntu packages dependencies
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install ${LSB_DIST} packages dependencies...${COLOR_END}"
case "${LSB_DIST}" in
  ubuntu)
    # manualy add ubuntu-toolchain-r ppa to get latest g++/gcc compilers
    echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DIST_VERSION} main" > "/etc/apt/sources.list.d/ubuntu-toolchain-r-test-${DIST_VERSION}.list"
    echo "deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DIST_VERSION} main" >> "/etc/apt/sources.list.d/ubuntu-toolchain-r-test-${DIST_VERSION}.list"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F

    apt-get update > /dev/null
    apt-get install -yqq --no-install-suggests --no-install-recommends --force-yes build-essential curl git "gcc-${GCC_VERSION}" g++-"${GCC_VERSION}" gdb python openssl jq > /dev/null
  ;;

  debian)

    apt-get update > /dev/null
    apt-get install -yqq --no-install-suggests --no-install-recommends --force-yes build-essential curl git "gcc-${GCC_VERSION}" g++-"${GCC_VERSION}" gdb python openssl jq > /dev/null
  ;;
esac


# install nodejs in required version
if [[ $(node --version) != "v${NODE_VERSION}" ]]; then
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install nodejs v${NODE_VERSION}...${COLOR_END}"

  curl --silent -kO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" > /dev/null
  tar -xsSf "node-v${NODE_VERSION}-linux-x64.tar.gz" -C /usr/local --strip-components=1 > /dev/null
  rm "node-v${NODE_VERSION}-linux-x64.tar.gz" > /dev/null

  if [[ -e /usr/local/bin/nodejs ]]; then
    rm -f /usr/local/bin/nodejs > /dev/null
  fi

  ln -s /usr/local/bin/node /usr/local/bin/nodejs > /dev/null
fi

# configure npm
npm cache clean --force > /dev/null

npm config set progress false > /dev/null
npm config set strict-ssl false > /dev/null


# install global npm dependencies
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install testim cli...${COLOR_END}"
npm install -g @testim/testim-cli > /dev/null

# check if pm2 binary is accessible in $PATH
set +e
pm2 > /dev/null
PM2_STATUS=$?
set -e

[[ $PM2_STATUS == 0 && $(pm2 --version) == "${GLOBAL_PM2_VERSION}" ]] || (
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install pm2...${COLOR_END}"
  echo -e

  npm uninstall -g pm2 > /dev/null || true

  if [[ "${GLOBAL_PM2_VERSION}" == "" ]]; then
    npm install -g pm2  > /dev/null
  else
    npm install -g pm2@${GLOBAL_PM2_VERSION}  > /dev/null
  fi
)
