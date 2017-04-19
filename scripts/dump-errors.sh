#!/bin/bash

#-------------------------------------------------------------------------------
#
#   Kuzzle end-to-end test sandbox
#
#   Script aim: output all infos to allow bug investigation
#   - output docker container status
#   - output proxy infos (container details, logs)
#   - output kuzzle cores infos (container details, logs)
#   - output chaos mode logs if enabled
#
#-------------------------------------------------------------------------------

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

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

if [[ -e "${SANDBOX_DIR}/chaos_mode.log" ]]; then
  echo -e "- ${COLOR_BLUE}chaos mode logs:$COLOR_END"
  cat "${SANDBOX_DIR}/chaos_mode.log"
fi
