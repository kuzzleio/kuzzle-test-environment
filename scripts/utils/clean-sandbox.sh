#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

docker kill $(docker ps -q)
docker rm -vf $(docker ps -aq)
docker rmi tests/kuzzle-base

rm -rf "${SANDBOX_DIR}"
