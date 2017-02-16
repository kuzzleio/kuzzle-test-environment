#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_LBLUE="\e[94m"
COLOR_YELLOW="\e[33m"
COLOR_LYELLOW="\e[93m"

echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Runing tests...$COLOR_END"
echo -e

echo -e "-> ${COLOR_BLUE}node version:$COLOR_END"
node --version

echo -e "-> ${COLOR_BLUE}npm version:$COLOR_END"
npm --version

echo -e "-> ${COLOR_BLUE}pm2 version:$COLOR_END"
pm2 --version

echo -e "-> ${COLOR_BLUE}python version:$COLOR_END"
python --version

echo -e "-> ${COLOR_BLUE}gcc version:$COLOR_END"
gcc --version

pushd "/tmp/sandbox" &>/dev/null
  pushd kuzzle-proxy &>/dev/null
    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Runing kuzzle-proxy tests...$COLOR_END"
    echo -e

    npm run test

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}kuzzle-proxy tests ok !$COLOR_END"
    echo -e
  popd &>/dev/null

  pushd kuzzle &>/dev/null
    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Runing kuzzle tests...$COLOR_END"
    echo -e

    npm run test

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}kuzzle tests ok !$COLOR_END"
    echo -e
  popd &>/dev/null
popd &>/dev/null
