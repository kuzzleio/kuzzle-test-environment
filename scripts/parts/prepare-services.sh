#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

ELASTIC_HOST=${kuzzle_services__db__host:-localhost}
ELASTIC_PORT=${kuzzle_services__db__port:-9200}

set -e

docker pull elasticsearch:"${ES_VERSION:-latest}"
docker pull redis:"${REDIS_VERSION:-latest}"
docker pull selenium/hub
docker pull testim/node-chrome
docker pull testim/node-firefox:latest

# run external services through docker (todo: check if needed)
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Start elasticsearch service (docker) ...${COLOR_END}";
docker inspect elasticsearch &>/dev/null && sh -c "docker kill elasticsearch || true" && sh -c "docker rm -vf elasticsearch || true"
docker run --network=bridge --detach --name elasticsearch --publish 9200:9200 elasticsearch:"${ES_VERSION:-latest}"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Start redis service (docker) ...${COLOR_END}";
docker inspect redis &>/dev/null && sh -c "docker kill redis || true" && sh -c "docker rm -vf redis || true"
docker run --network=bridge --detach --name redis --publish 6379:6379 redis:"${REDIS_VERSION:-latest}"

# wait for services to start
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Waiting for elasticsearch to be available${COLOR_END}"
while ! curl -f -s -o /dev/null "http://${ELASTIC_HOST}:${ELASTIC_PORT}"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to elasticsearch at http://${ELASTIC_HOST}:${ELASTIC_PORT}${COLOR_END}"
    sleep 1
done
# create a tmp index just to force the shards to init
curl -XPUT -s -o /dev/null "http://${ELASTIC_HOST}:${ELASTIC_PORT}/%25___tmp"
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Elasticsearch is up. Waiting for shards to be active (can take a while)${COLOR_END}"
E=$(curl -s "http://${ELASTIC_HOST}:${ELASTIC_PORT}/_cluster/health?wait_for_status=yellow&wait_for_active_shards=1&timeout=60s")
curl -XDELETE -s -o /dev/null "http://${ELASTIC_HOST}:${ELASTIC_PORT}/%25___tmp"

if ! (echo ${E} | grep -E '"status":"(yellow|green)"' > /dev/null); then
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Could not connect to elasticsearch in time. Aborting...${COLOR_END}"
    exit 1
fi
