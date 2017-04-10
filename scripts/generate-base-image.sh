#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle environment installation...${COLOR_END}"


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

case "$lsb_dist" in
  ubuntu)
    if command -v lsb_release > /dev/null 2>&1; then
      dist_version="$(lsb_release --codename | cut -f2)"
    fi
    if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
      dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
    fi
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

if [[ ! $(docker images -a | grep tests/kuzzle-base) ]]; then
  # create container with all dependencies needed to run kuzzle env components
  # dynamicly created here because we can setup easily
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Generate image 'tests/kuzzle-base' based on ${lsb_dist}:${dist_version} image ...${COLOR_END}"

  docker run \
    --network="bridge" \
    --name "kuzzle-base" \
    -e "GCC_VERSION=$GCC_VERSION" \
    -e "NODE_VERSION=$NODE_VERSION" \
    -e "GLOBAL_PM2_VERSION=$GLOBAL_PM2_VERSION" \
    -e "NODE_ENV=$NODE_ENV" \
    -e "DEBUG=$DEBUG" \
    -e "CC=gcc-$GCC_VERSION" \
    -e "CXX=g++-$GCC_VERSION" \
    --volume "$SCRIPT_DIR:/scripts" \
    "${lsb_dist}:${dist_version}" \
      bash -c 'bash /scripts/install-deps.sh'

  # create base image "tests/kuzzle-base:latest" based on previous container
  docker commit \
    --change 'WORKDIR /tmp/sandbox/app' \
    kuzzle-base \
    tests/kuzzle-base:latest
else
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Generated image 'tests/kuzzle-base' exists, using it ...${COLOR_END}"
fi
