#!/bin/bash
set -ex

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

# get all exported env variables begining with "proxy_"
vars=($(env | grep -e "^proxy_"));
opt=" "
for ((i=0; i<${#vars[@]}; ++i));
do
  # format env vars to docker run options format
  opt="-e ${vars[i]} ${opt}"
done

docker inspect "proxy" &>/dev/null && sh -c "docker kill proxy || true" && sh -c "docker rm -vf proxy || true"

docker run --network="bridge" \
           --detach \
           --name "proxy" \
           --volume "/tmp/sandbox/kuzzle-proxy:/tmp/sandbox/app" \
           --publish "7512:7512" \
           ${opt} \
           tests/kuzzle-base \
             bash -c 'pm2 start --silent ./docker-compose/config/pm2.json && tail -f /dev/null'

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle proxy '${PROXY_VERSION}' started ...${COLOR_END}"
