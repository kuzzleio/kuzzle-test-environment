#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

set -e

docker pull elasticsearch:"${ES_VERSION:-latest}"
docker pull redis:"${REDIS_VERSION:-latest}"
docker pull selenium/hub
docker pull testim/node-chrome
docker pull testim/node-firefox:latest

# run external services through docker (todo: check if needed)
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Start elasticsearch service (docker) ...${COLOR_END}";
sysctl -w vm.max_map_count=262144
docker inspect elasticsearch &>/dev/null && sh -c "docker kill elasticsearch || true" && sh -c "docker rm -vf elasticsearch || true"
docker run --network=bridge --detach --name elasticsearch --publish 9200:9200 elasticsearch:"${ES_VERSION:-latest}"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Start redis service (docker) ...${COLOR_END}";
docker inspect redis &>/dev/null && sh -c "docker kill redis || true" && sh -c "docker rm -vf redis || true"
docker run --network=bridge --detach --name redis --publish 6379:6379 redis:"${REDIS_VERSION:-latest}"

# wait for services to start
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Waiting for elasticsearch to be available${COLOR_END}"
while ! curl -f -s -o /dev/null "${ELASTIC_HOST}"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to elasticsearch at ${ELASTIC_HOST}${COLOR_END}"
    sleep 1
done
# create a tmp index just to force the shards to init
curl -XPUT -s -o /dev/null "${ELASTIC_HOST}/%25___tmp"
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Elasticsearch is up. Waiting for shards to be active (can take a while)${COLOR_END}"
E=$(curl -s "${ELASTIC_HOST}/_cluster/health?wait_for_status=yellow&wait_for_active_shards=1&timeout=60s")
curl -XDELETE -s -o /dev/null "${ELASTIC_HOST}/%25___tmp"

if ! (echo ${E} | grep -E '"status":"(yellow|green)"' > /dev/null); then
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Could not connect to elasticsearch in time. Aborting...${COLOR_END}"
    exit 1
fi
