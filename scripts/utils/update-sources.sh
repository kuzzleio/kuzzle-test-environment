#!/bin/bash
COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

pushd "/tmp/sandbox" > /dev/null
  pushd "kuzzle" > /dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Update kuzzle '${KUZZLE_VERSION}' ...${COLOR_END}"

    git pull > /dev/null

    pushd plugins/enabled > /dev/null
      for PLUGIN in ./*; do
        if [ -d "${PLUGIN}" ]; then
          pushd "${PLUGIN}" > /dev/null
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Update kuzzle plugin '${PLUGIN}' ...${COLOR_END}"

            git pull > /dev/null
          popd > /dev/null
        fi
      done
    popd > /dev/null
  popd > /dev/null
  pushd "kuzzle-proxy" > /dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Update proxy '${PROXY_VERSION}' ...${COLOR_END}"

    git pull > /dev/null

    pushd plugins/enabled > /dev/null
      for PLUGIN in ./*; do
        if [ -d "${PLUGIN}" ]; then
          pushd "${PLUGIN}" > /dev/null
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Update proxy plugin '${PLUGIN}' ...${COLOR_END}"

            git pull > /dev/null
          popd > /dev/null
        fi
      done
    popd > /dev/null
  popd > /dev/null

  pushd "kuzzle-backoffice" > /dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Update kuzzle backoffice '${BACKOFFICE_VERSION}' ...${COLOR_END}"

    git pull > /dev/null
  popd > /dev/null
popd > /dev/null
