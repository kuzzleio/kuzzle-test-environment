#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

echo -n "" > $CHAOS_LOG

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}---- CHAOS MODE STARTED ----$COLOR_END"
echo "[$(date --rfc-3339 seconds)] - ---- CHAOS MODE STARTED ----" >> $CHAOS_LOG

# enabled only when run-tests.sh script is running
while [[ $(ps x | grep run-tests.sh | grep bash) ]]; do
  # wait beetween 5 and 20 seconds
  sleep $(( RANDOM%17/3*3+5 ))

  # randomly choose a kuzzle node
  KUZZLE_NODE=$(((RANDOM%KUZZLE_NODES)+1))

  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}CHAOS - RESTART kuzzle_${KUZZLE_NODE} ...$COLOR_END"
  echo "[$(date --rfc-3339 seconds)] - CHAOS - RESTART kuzzle_${KUZZLE_NODE} ..." >> $CHAOS_LOG

  # restart choosen kuzzle node
  # docker restart "kuzzle_${KUZZLE_NODE}" > /dev/null &
  docker exec -ti "kuzzle_${KUZZLE_NODE}" pm2 restart all > /dev/null &
done

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}---- CHAOS MODE STOPPED ----$COLOR_END"
echo "[$(date --rfc-3339 seconds)] - ---- CHAOS MODE STOPPED ----" >> $CHAOS_LOG
