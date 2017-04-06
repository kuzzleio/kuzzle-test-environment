#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

echo -e "${COLOR_BLUE}Tests errored${COLOR_END}"

echo -e "- ${COLOR_BLUE}docker containers status:$COLOR_END"
docker ps -a

echo -e "- ${COLOR_BLUE}proxy container status:$COLOR_END"
docker inspect "proxy"

echo -e "- ${COLOR_BLUE}proxy container logs:$COLOR_END"
docker logs "proxy"

echo -e "- ${COLOR_BLUE}proxy pm2 logs:$COLOR_END"
docker exec -ti "proxy" bash -c "tail -n 100000 /root/.pm2/logs/*"

for i in $(seq 1 ${KUZZLE_NODES:-1});
do
  echo -e "- ${COLOR_BLUE}kuzzle ${i} container status:$COLOR_END"
  docker inspect "kuzzle_${i}"

  echo -e "- ${COLOR_BLUE}kuzzle ${i} container logs:$COLOR_END"
  docker logs "kuzzle_${i}"

  echo -e "- ${COLOR_BLUE}kuzzle ${i} pm2 logs:$COLOR_END"
  docker exec -ti "kuzzle_${i}" bash -c "tail -n 100000 /root/.pm2/logs/*"
done

if [[ -e /tmp/sandbox/chaos_mode.log ]]; then
  echo -e "- ${COLOR_BLUE}chaos mode logs:$COLOR_END"
  cat /tmp/sandbox/chaos_mode.log
fi
