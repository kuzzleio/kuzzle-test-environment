#!/bin/bash

docker kill $(docker ps -q)
docker rm -vf $(docker ps -aq)
docker rmi tests/kuzzle-base

rm -rf /tmp/sandbox/
