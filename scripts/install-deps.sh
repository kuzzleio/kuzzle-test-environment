#!/bin/bash

gcc --version
g++ --version

set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

# install debian packages dependencies
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install debian packages dependencies...${COLOR_END}"

apt-get update
apt-get install -yq --no-install-suggests --no-install-recommends --force-yes build-essential curl git gcc-"$GCC_VERSION" g++-"$GCC_VERSION" gdb python openssl jq

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

npm config set progress false
npm config set strict-ssl false

npm i -g @testim/testim-cli

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
