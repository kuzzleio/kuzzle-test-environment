#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

SANDBOX_DIR="/tmp/sandbox"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading kuzzle backoffice '${BACKOFFICE_REPO}@${BACKOFFICE_VERSION}' ...${COLOR_END}"

pushd "${SANDBOX_DIR}" > /dev/null
  if [ -d "kuzzle-backoffice" ]; then
    rm -rf ./kuzzle-backoffice
  fi

  git clone "https://${GH_TOKEN}@github.com/${BACKOFFICE_REPO}.git" -b "${BACKOFFICE_VERSION}" kuzzle-backoffice > /dev/null

  pushd kuzzle-backoffice > /dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle backoffice dependencies ...${COLOR_END}"
    npm run install_deps > /dev/null

    if [[ "${BACKOFFICE_SDK_VERSION}" != "" ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Override backoffice SDK '${BACKOFFICE_SDK_VERSION}' ...${COLOR_END}"

      npm uninstall kuzzle-sdk > /dev/null || true
      npm install "${BACKOFFICE_SDK_VERSION/@/#}" > /dev/null
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Using default SDK embeded with backoffice...${COLOR_END}"
    fi
  popd > /dev/null
popd > /dev/null
