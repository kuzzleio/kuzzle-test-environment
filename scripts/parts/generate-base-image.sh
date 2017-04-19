#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle environment installation...${COLOR_END}"

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
