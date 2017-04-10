#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"


lsb_dist=''
dist_version=''

if command -v lsb_release > /dev/null 2>&1; then
  lsb_dist="$(lsb_release -si)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
  lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
  lsb_dist='debian'
fi
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"


# install debian packages dependencies
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install ${lsb_dist} packages dependencies...${COLOR_END}"


case "$lsb_dist" in
  ubuntu)
    if command -v lsb_release > /dev/null 2>&1; then
      dist_version="$(lsb_release --codename | cut -f2)"
    fi
    if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
      dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
    fi

    echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${dist_version} main" > "/etc/apt/sources.list.d/ubuntu-toolchain-r-test-${dist_version}.list"
    echo "deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${dist_version} main" >> "/etc/apt/sources.list.d/ubuntu-toolchain-r-test-${dist_version}.list"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F
  ;;

  debian)
    dist_version="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
    case "$dist_version" in
      9)
        dist_version="stretch"
      ;;
      8)
        dist_version="jessie"
      ;;
      7)
        dist_version="wheezy"
      ;;
    esac
  ;;
esac


set -e

apt-get update > /dev/null
apt-get install -yqq --no-install-suggests --no-install-recommends --force-yes build-essential curl git gcc-"$GCC_VERSION" g++-"$GCC_VERSION" gdb python openssl jq > /dev/null

# install nodejs in required version
if [[ $(node --version) != "v$NODE_VERSION" ]]; then
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install nodejs v${NODE_VERSION}...${COLOR_END}"

  curl --silent -kO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" > /dev/null
  tar -xsSf "node-v${NODE_VERSION}-linux-x64.tar.gz" -C /usr/local --strip-components=1 > /dev/null
  rm "node-v${NODE_VERSION}-linux-x64.tar.gz" > /dev/null

  if [[ -e /usr/local/bin/nodejs ]]; then
    rm -f /usr/local/bin/nodejs > /dev/null
  fi

  ln -s /usr/local/bin/node /usr/local/bin/nodejs > /dev/null
fi

npm cache clean --force > /dev/null

npm config set progress false > /dev/null
npm config set strict-ssl false > /dev/null

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

#echo PATH="/tmp/.npm-global/bin:$PATH" >> /etc/environment
#source /etc/environment
