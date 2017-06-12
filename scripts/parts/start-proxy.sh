#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

vars=($PROXY_EXTRA_ENV);
opt=" "
for ((i=0; i<${#vars[@]}; ++i));
do
  # format env vars to docker run options format
  opt="-e ${vars[i]} ${opt}"
done

if [[ -e /etc/proxyrc ]]; then
  opt="--volume /etc/proxyrc:/etc/proxyrc ${opt}"
fi

docker inspect "proxy" &>/dev/null && sh -c "docker kill proxy || true" && sh -c "docker rm -vf proxy || true"

docker run --network="bridge" \
           --detach \
           --name "proxy" \
           --volume "${SANDBOX_DIR}/kuzzle-proxy:${SANDBOX_DIR}/app" \
           --publish "7512:7512" \
           -e "DEBUG=$DEBUG" \
           -e "DEBUG_EXPAND=$DEBUG_EXPAND" \
           -e "DEBUG_DEPTH=$DEBUG_DEPTH" \
           -e "DEBUG_MAX_ARRAY_LENGTH=$DEBUG_MAX_ARRAY_LENGTH" \
           -e "DEBUG_SHOW_HIDDEN=$DEBUG_SHOW_HIDDEN" \
           -e "DEBUG_COLORS=$DEBUG_COLORS" \
           -e "NODE_ENV=$NODE_ENV" \
           ${opt} \
           tests/kuzzle-base \
             bash -c 'pm2 start --silent ./docker-compose/config/pm2.json && tail -f /dev/null'

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle proxy '${PROXY_VERSION}' started ...${COLOR_END}"
