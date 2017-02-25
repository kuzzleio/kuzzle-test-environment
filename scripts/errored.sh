#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

echo -e "${COLOR_BLUE}Tests errored${COLOR_END}"

echo -e "- ${COLOR_BLUE}kuzzle version:$COLOR_END"
echo "${KUZZLE_REPO}#${KUZZLE_VERSION}"

if [[ "$KUZZLE_COMMON_OBJECT_VERSION" == "" ]]; then
  echo -e "- ${COLOR_BLUE}overrided kuzzle common object:$COLOR_END"
  echo "${KUZZLE_COMMON_OBJECT_VERSION}"
fi

echo -e "- ${COLOR_BLUE}proxy version:$COLOR_END"
echo "${PROXY_REPO}#${PROXY_VERSION}"

if [[ "$PROXY_COMMON_OBJECT_VERSION" == "" ]]; then
  echo -e "- ${COLOR_BLUE}overrided proxy common object:$COLOR_END"
  echo "${PROXY_COMMON_OBJECT_VERSION}"
fi

echo -e "- ${COLOR_BLUE}node version:$COLOR_END"
node --version

echo -e "- ${COLOR_BLUE}npm version:$COLOR_END"
npm --version

echo -e "- ${COLOR_BLUE}pm2 version:$COLOR_END"
pm2 --version

echo -e "- ${COLOR_BLUE}python version:$COLOR_END"
python --version

echo -e "- ${COLOR_BLUE}gcc version:$COLOR_END"
gcc --version

for i in $(seq 1 ${KUZZLE_NODES:-1});
do
  echo -e "- ${COLOR_BLUE}kuzzle ${i} container logs:$COLOR_END"
  docker logs "kuzzle_${i}"

  echo -e "- ${COLOR_BLUE}kuzzle ${i} pm2 logs:$COLOR_END"
  docker exec -ti "kuzzle_${i}" pm2 logs --lines 1000
done
