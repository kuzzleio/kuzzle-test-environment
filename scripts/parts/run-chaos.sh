#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

SANDBOX_DIR="/tmp/sandbox"
KUZZLE_NODES=${KUZZLE_NODES:-1}
CHAOS_LOG="${SANDBOX_DIR}/chaos_mode.log"

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
