#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

START_INSTALL="$(date +%s)"
TIMEOUT_INSTALL=$START_INSTALL+60*15

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Reset kuzzle environment data ...${COLOR_END}"
echo "RESET KUZZLE DATA" > /tmp/sandbox-status

docker exec -ti kuzzle_1 ./bin/kuzzle reset --noint &>/dev/null

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Restarting kuzzle proxy instance ...${COLOR_END}"
docker exec -ti "proxy" pm2 restart all &>/dev/null

sleep 10

for i in $(seq 1 ${KUZZLE_NODES});
do
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Restarting kuzzle ${i}/${KUZZLE_NODES} instance ...${COLOR_END}"
  docker exec -ti "kuzzle_${i}" pm2 restart all &>/dev/null
done

sleep 60

# for i in $(seq 1 ${KUZZLE_NODES:-1});
# do
#   echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Stopping kuzzle ${i}/${KUZZLE_NODES} instance ...${COLOR_END}"
#   docker exec -ti "kuzzle_${i}" pm2 stop all
#   docker exec -ti "kuzzle_${i}" pm2 flush
# done
#
# echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Stopping kuzzle proxy instance ...${COLOR_END}"
# docker exec -ti "proxy" pm2 stop all
# docker exec -ti "proxy" pm2 flush
#
# echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Restarting kuzzle services instances ...${COLOR_END}"
# bash -c "$SCRIPT_DIR/parts/prepare-services.sh"
#
# echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Restarting kuzzle proxy instance ...${COLOR_END}"
# bash -c "$SCRIPT_DIR/parts/start-proxy.sh"
#
# echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Restarting kuzzle instance ...${COLOR_END}"
# bash -c "$SCRIPT_DIR/parts/start-kuzzle.sh"
#
#
# echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Waiting for kuzzle to be available${COLOR_END}"
# while [[ "$(date +%s)" -lt "${TIMEOUT_INSTALL}" ]] && ! curl -f -s -o /dev/null "${SANDBOX_ENDPOINT}"
# do
#     echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to kuzzle at ${SANDBOX_ENDPOINT}${COLOR_END}"
#     sleep 2
# done
#
# if ! curl -f -s -o /dev/null "${SANDBOX_ENDPOINT}"; then
#   echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle installation timed out (> 15min)${COLOR_END}"
#
#   #kill_process
#
#   exit 1
# else
#   echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle available at ${SANDBOX_ENDPOINT}${COLOR_END}"
#
#   exit 0
# fi
