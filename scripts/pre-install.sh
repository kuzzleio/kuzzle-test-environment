#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Installing system dependencies${COLOR_END}"
bash -c "$SCRIPT_DIR/install-deps.sh"

# install docker
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install docker ...${COLOR_END}"; \
curl --silent -ksSL https://get.docker.com/ | sh

# start docker daemon if needed
docker ps -q || (
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Start docker daemon ...${COLOR_END}"; \
  service docker start && sleep 3
)

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Create base container to run kuzzle services${COLOR_END}"
bash -c "$SCRIPT_DIR/generate-base-image.sh"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Installing services dependencies (elasticsearch & redis)${COLOR_END}"
bash -c "$SCRIPT_DIR/install-services.sh"
