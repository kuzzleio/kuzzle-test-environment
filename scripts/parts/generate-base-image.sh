#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

LSB_DIST=""
DIST_VERSION=""

SANDBOX_DIR="/tmp/sandbox"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle environment installation...${COLOR_END}"

if command -v lsb_release > /dev/null 2>&1; then
  LSB_DIST="$(lsb_release -si)"
fi
if [ -z "${LSB_DIST}" ] && [ -r /etc/lsb-release ]; then
  LSB_DIST="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "${LSB_DIST}" ] && [ -r /etc/debian_version ]; then
  LSB_DIST='debian'
fi
LSB_DIST="$(echo "${LSB_DIST}" | tr '[:upper:]' '[:lower:]')"

case "${LSB_DIST}" in
  ubuntu)
    if command -v lsb_release > /dev/null 2>&1; then
      DIST_VERSION="$(lsb_release --codename | cut -f2)"
    fi
    if [ -z "${DIST_VERSION}" ] && [ -r /etc/lsb-release ]; then
      DIST_VERSION="$(. /etc/lsb-release && echo "${DISTRIB_CODENAME}")"
    fi
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
  ;;
esac

if [[ ! $(docker images -a | grep tests/kuzzle-base) ]]; then
  # create container with all dependencies needed to run kuzzle env components
  # dynamicly created here because we can setup easily
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Generate image 'tests/kuzzle-base' based on ${LSB_DIST}:${DIST_VERSION} image ...${COLOR_END}"

  docker run \
    --network="bridge" \
    --name "kuzzle-base" \
    -e "GCC_VERSION=${GCC_VERSION}" \
    -e "NODE_VERSION=${NODE_VERSION}" \
    -e "GLOBAL_PM2_VERSION=${GLOBAL_PM2_VERSION}" \
    -e "NODE_ENV=${NODE_ENV}" \
    -e "DEBUG=${DEBUG}" \
    -e "CC=gcc-${GCC_VERSION}" \
    -e "CXX=g++-${GCC_VERSION}" \
    --volume "${SCRIPT_DIR}:/scripts" \
    "${LSB_DIST}:${DIST_VERSION}" \
      bash -c 'bash /scripts/parts/install-sys-deps.sh'

  # create base image "tests/kuzzle-base:latest" based on previous container
  docker commit \
    kuzzle-base \
    tests/kuzzle-base:raw

  # create base image "tests/kuzzle-base:latest" based on previous container
  docker commit \
    --change "WORKDIR ${SANDBOX_DIR}/app" \
    kuzzle-base \
    tests/kuzzle-base:latest
else
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Generated image 'tests/kuzzle-base' already exists ...${COLOR_END}"
fi
