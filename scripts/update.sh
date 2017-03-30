#!/bin/bash
COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

pushd "/tmp/sandbox" > /dev/null
  pushd "kuzzle" > /dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Update kuzzle '${PLUGIN}' ...${COLOR_END}"

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
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Update proxy '${PLUGIN}' ...${COLOR_END}"

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
popd > /dev/null

for i in $(seq 1 ${KUZZLE_NODES:-1});
do
  docker exec -ti "kuzzle_${i}" pm2 stop all
  docker exec -ti "kuzzle_${i}" pm2 flush
done

docker exec -ti "proxy" pm2 flush
docker exec -ti "proxy" pm2 restart all

for i in $(seq 1 ${KUZZLE_NODES:-1});
do
  docker exec -ti "kuzzle_${i}" pm2 start 0
done
