#!/bin/bash
trap kill_process INT

function kill_process() {
  # kill remaining process
  ps aux | grep /scripts/install-proxy.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/install-kuzzle.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/start-proxy.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/start-kuzzle.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep gyp | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep npm | awk '{print $2}' | xargs kill -9 > /dev/null

  exit 1
}


COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle environment installation...${COLOR_END}"

if [[ ! $(docker images -a | grep tests/kuzzle-base) ]]; then
  # create container with all dependencies needed to run kuzzle env components
  # dynamicly created here because we can setup easily
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Generate image 'tests/kuzzle-base' ...${COLOR_END}"

  docker run \
    --network="bridge" \
    --name "kuzzle-base" \
    -e "GCC_VERSION=$GCC_VERSION" \
    -e "NODE_VERSION=$NODE_VERSION" \
    -e "GLOBAL_PM2_VERSION=$GLOBAL_PM2_VERSION" \
    -e "NODE_ENV=$NODE_ENV" \
    -e "DEBUG=$DEBUG" \
    --volume "$SCRIPT_DIR:/scripts" \
    debian:jessie \
      bash -c 'bash /scripts/install-deps.sh'

  # create base image "tests/kuzzle-base:latest" based on previous container
  docker commit \
    --change 'WORKDIR /tmp/sandbox/app' \
    kuzzle-base \
    tests/kuzzle-base:latest
else
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Generated image 'tests/kuzzle-base' exists, using it ...${COLOR_END}"
fi

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install projects...${COLOR_END}"

if [ ! -d "/tmp/sandbox" ]; then
  mkdir -p "/tmp/sandbox"
fi

START_INSTALL="$(date +%s)"
TIMEOUT_INSTALL=$START_INSTALL+60*15

pushd "/tmp/sandbox" > /dev/null
  # insall and start proxy in a background process
  bash -c "$SCRIPT_DIR/install-proxy.sh && $SCRIPT_DIR/start-proxy.sh" &

  # insall and start kuzzle nodes in a background process
  bash -c "$SCRIPT_DIR/install-kuzzle.sh && $SCRIPT_DIR/start-kuzzle.sh" &
popd > /dev/null

echo -e

# wait for kuzzle to be available to exit
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Waiting for kuzzle to be available${COLOR_END}"
while [[ "$(date +%s)" -lt "${TIMEOUT_INSTALL}" ]] && ! curl -f -s -o /dev/null "http://localhost:7512"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to kuzzle at http://localhost:7512${COLOR_END}"
    sleep 8
done

if ! curl -f -s -o /dev/null "http://localhost:7512"; then
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle installation timed out (> 15min)${COLOR_END}"

  kill_process

  exit 1
else
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle available at http://localhost:7512${COLOR_END}"

  exit 0
fi
