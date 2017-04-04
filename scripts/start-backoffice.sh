#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

set +e
while [[ $(docker inspect "proxy" -f "{{ .State.Status }}") != "running" ]]  &>/dev/null;
do
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still waiting for proxy to be available before starting kuzzle backoffice${COLOR_END}"
  sleep 2
done
set -e

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle backoffice...${COLOR_END}"

docker inspect "backoffice" &>/dev/null && sh -c "docker kill backoffice || true" && sh -c "docker rm -vf backoffice || true"

docker run --network="bridge" \
           --detach \
           --link "proxy:proxy" \
           --name "backoffice" \
           --volume "/tmp/sandbox/kuzzle-backoffice:/tmp/sandbox/app" \
           --publish "3000:3000" \
           -e "DEBUG=$DEBUG" \
           -e "NODE_ENV=$NODE_ENV" \
           tests/kuzzle-base \
             bash -c 'npm run dev'

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting selenium hub...${COLOR_END}"

docker inspect "hub" &>/dev/null && sh -c "docker kill hub || true" && sh -c "docker rm -vf hub || true"

docker run --network="bridge" \
          --detach \
          --name "hub" \
          --link "proxy:proxy" \
          --link "backoffice:backoffice" \
          --publish "4444:4444" \
          -e "GRID_MAX_SESSION=50" \
          selenium/hub


echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting chrome...${COLOR_END}"

docker inspect "chrome" &>/dev/null && sh -c "docker kill chrome || true" && sh -c "docker rm -vf chrome || true"

docker run --network="bridge" \
         --detach \
         --name "chrome" \
         --link "hub:hub" \
         --link "proxy:proxy" \
         --link "backoffice:backoffice" \
         --volume "/dev/shm:/dev/shm" \
         -e "HUB_PORT_4444_TCP_ADDR=hub" \
         -e "HUB_PORT_4444_TCP_PORT=4444" \
         testim/node-chrome


echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting firefox...${COLOR_END}"

docker inspect "firefox" &>/dev/null && sh -c "docker kill firefox || true" && sh -c "docker rm -vf firefox || true"

docker run --network="bridge" \
          --detach \
          --name "firefox" \
          --link "hub:hub" \
          --link "proxy:proxy" \
          --link "backoffice:backoffice" \
          --volume "/dev/shm:/dev/shm" \
          -e "HUB_PORT_4444_TCP_ADDR=hub" \
          -e "HUB_PORT_4444_TCP_PORT=4444" \
          testim/node-firefox

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle backoffice '${BACKOFFICE_VERSION}' started ...${COLOR_END}"
