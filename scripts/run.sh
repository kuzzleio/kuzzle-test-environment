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

pushd "$HOME" &>/dev/null
  pushd kuzzle-proxy &>/dev/null
  npm run test
  popd &>/dev/null

  pushd kuzzle &>/dev/null
  npm run test
  popd &>/dev/null
popd &>/dev/null
