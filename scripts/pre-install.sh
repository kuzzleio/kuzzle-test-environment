#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Installing system dependencies${COLOR_END}"
bash "$SCRIPT_DIR/install-deps.sh"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Installing services dependencies (elasticsearch & redis)${COLOR_END}"
bash "$SCRIPT_DIR/install-services.sh"

npm i -g @testim/testim-cli
