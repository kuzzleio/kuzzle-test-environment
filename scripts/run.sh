#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting functional testing suite...$COLOR_END"

if [[ $ENABLE_CHAOS_MODE == "true" ]]; then
  bash "$SCRIPT_DIR/run-chaos.sh" &
fi

pushd "/tmp/sandbox" &>/dev/null
  pushd kuzzle-proxy &>/dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle-proxy tests...$COLOR_END"

    if [[ $(npm run | grep functional-testing) ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle-proxy functional tests...$COLOR_END"

      npm run functional-testing

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}kuzzle-proxy functional tests ok !$COLOR_END"
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Skipping kuzzle-proxy, no functional tests found.$COLOR_END"
    fi

  popd &>/dev/null

  pushd kuzzle &>/dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle tests...$COLOR_END"

    if [[ $(npm run | grep functional-testing) ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle functional tests...$COLOR_END"

      npm run functional-testing

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}kuzzle tests functional ok !$COLOR_END"
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Skipping kuzzle, no functional tests found.$COLOR_END"
    fi
  popd &>/dev/null
popd &>/dev/null
