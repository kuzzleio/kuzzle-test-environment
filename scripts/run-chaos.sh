#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

KUZZLE_NODES=${KUZZLE_NODES:-1}

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}---- CHAOS MODE STARTED ----$COLOR_END"

# enabled only when run.sh script is running
while [[ $(ps x | grep run.sh | grep bash) ]]; do
  # wait beetween 5 and 20 seconds
  sleep $(( RANDOM%17/3*3+5 ))

  # randomly choose a kuzzle node
  KUZZLE_NODE=$(((RANDOM%KUZZLE_NODES)+1))

  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}CHAOS - RESTART kuzzle_${KUZZLE_NODE} ...$COLOR_END"

  # restart choosen kuzzle node
  docker restart "kuzzle_${KUZZLE_NODE}" > /dev/null &
done

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}---- CHAOS MODE STOPPED ----$COLOR_END"
