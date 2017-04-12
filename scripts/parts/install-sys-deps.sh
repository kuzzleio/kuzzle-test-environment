#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"


LSB_DIST=''
DIST_VERSION=''

if command -v lsb_release > /dev/null 2>&1; then
  LSB_DIST="$(lsb_release -si)"
fi
if [ -z "${LSB_DIST}" ] && [ -r /etc/lsb-release ]; then
  LSB_DIST="$(. /etc/lsb-release && echo "${DISTRIB_ID}")"
fi
if [ -z "${LSB_DIST}" ] && [ -r /etc/debian_version ]; then
  LSB_DIST='debian'
fi
LSB_DIST="$(echo "$LSB_DIST" | tr '[:upper:]' '[:lower:]')"


# install debian/ubuntu packages dependencies
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install ${LSB_DIST} packages dependencies...${COLOR_END}"

case "${LSB_DIST}" in
  ubuntu)
    if command -v lsb_release > /dev/null 2>&1; then
      DIST_VERSION="$(lsb_release --codename | cut -f2)"
    fi
    if [ -z "${DIST_VERSION}" ] && [ -r /etc/lsb-release ]; then
      DIST_VERSION="$(. /etc/lsb-release && echo "${DISTRIB_CODENAME}")"
    fi

    # manualy add ubuntu-toolchain-r ppa to get latest g++/gcc compilers
    echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DIST_VERSION} main" > "/etc/apt/sources.list.d/ubuntu-toolchain-r-test-${DIST_VERSION}.list"
    echo "deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${DIST_VERSION} main" >> "/etc/apt/sources.list.d/ubuntu-toolchain-r-test-${DIST_VERSION}.list"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F

    apt-get update > /dev/null
    apt-get install -yqq --no-install-suggests --no-install-recommends --force-yes build-essential curl git "gcc-${GCC_VERSION}" g++-"${GCC_VERSION}" gdb python openssl jq > /dev/null
  ;;

  debian)
    DIST_VERSION="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
    case "${DIST_VERSION}" in
      9)
        DIST_VERSION="stretch"
      ;;
      8)
        DIST_VERSION="jessie"
      ;;
      7)
        DIST_VERSION="wheezy"
      ;;
    esac

    apt-get update > /dev/null
    apt-get install -yqq --no-install-suggests --no-install-recommends --force-yes build-essential curl git "gcc-${GCC_VERSION}" g++-"${GCC_VERSION}" gdb python openssl jq > /dev/null
  ;;
esac


set -e

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
