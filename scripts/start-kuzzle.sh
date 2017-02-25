
#!/bin/bash
set -ex

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

export kuzzle_services__internalBroker__socket=/tmp/kuzzle-broker.sock
export kuzzle_services__db__host=elasticsearch
export kuzzle_services__internalCache__node__host=redis
export kuzzle_services__memoryStorage__node__host=redis
export kuzzle_services__proxyBroker__host=proxy

# get all exported env variables begining with "kuzzle_"
vars=($(env | grep -e "^kuzzle_"));
opt=" "
for ((i=0; i<${#vars[@]}; ++i));
do
  # format env vars to docker run options format
  opt="-e ${vars[i]} ${opt}"
done

for i in $(seq 1 ${KUZZLE_NODES:-1});
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting ${i}/${KUZZLE_NODES:-1} kuzzle ...${COLOR_END}"

    docker inspect "kuzzle_${i}" &>/dev/null && sh -c "docker kill kuzzle_${i} || true" && sh -c "docker rm -vf kuzzle_${i} || true"

    docker run --network="bridge" \
               --detach \
               --name "kuzzle_${i}" \
               --link "proxy:proxy" \
               --link "elasticsearch:elasticsearch" \
               --link "redis:redis" \
               --volume "/tmp/sandbox/kuzzle:/tmp/sandbox/app" \
               ${opt} \
               tests/kuzzle-base \
                 bash -c 'pm2 start --silent ./docker-compose/config/pm2.json && tail -f /dev/null'
done

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle '${KUZZLE_VERSION}' started ...${COLOR_END}"
