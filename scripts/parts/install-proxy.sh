#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading kuzzle proxy '${PROXY_REPO}@${PROXY_VERSION}' ...${COLOR_END}"

pushd "${SANDBOX_DIR}" > /dev/null
  if [ -d "kuzzle-proxy" ]; then
    rm -rf ./kuzzle-proxy
  fi

  if [[ "${PROXY_PLUGINS}" == "" ]]; then
    git clone --recursive "https://${GH_TOKEN}@github.com/${PROXY_REPO}.git" -b "${PROXY_VERSION}" kuzzle-proxy > /dev/null
  else
    git clone "https://${GH_TOKEN}@github.com/${PROXY_REPO}.git" -b "${PROXY_VERSION}" kuzzle-proxy > /dev/null
  fi

  pushd kuzzle-proxy > /dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle proxy dependencies ...${COLOR_END}"
    npm install > /dev/null

    if [[ "${PROXY_COMMON_OBJECT_VERSION}" != "" ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Override proxy common objects '${PROXY_COMMON_OBJECT_VERSION}' ...${COLOR_END}"

      npm uninstall kuzzle-common-object > /dev/null || true
      npm install "${PROXY_COMMON_OBJECT_VERSION/@/#}" > /dev/null
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Using default common objects embeded with proxy...${COLOR_END}"
    fi

    if [[ "${LB_PROXY_VERSION}" != "" ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Override load balancer proxy version '${LB_PROXY_VERSION}' ...${COLOR_END}"

      npm uninstall kuzzle-proxy > /dev/null || true
      npm install "${LB_PROXY_VERSION/@/#}" > /dev/null
    fi

    if [ ! -d "plugins/enabled" ]; then
      mkdir -p "plugins/enabled"
    fi

    pushd plugins/enabled > /dev/null

      if [[ "${PROXY_PLUGINS}" != "" ]]; then
        echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle proxy plugin list overrided${COLOR_END}"

        rm -rf ./*

        set -f

        OIFS=$IFS;
        IFS=":";
        PROXY_PLUGINS=($PROXY_PLUGINS);
        IFS=$OIFS;

        for ((i=0; i<${#PROXY_PLUGINS[@]}; ++i)); do
          if [[ "${PROXY_PLUGINS[$i]}" != "" ]]; then

            OIFS=$IFS;
            IFS="@";
            PLUGIN_INFO=(${PROXY_PLUGINS[$i]});
            IFS=$OIFS;

            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading proxy plugin '${PLUGIN_INFO[0]}@${PLUGIN_INFO[1]:-master}' ...${COLOR_END}"
            git clone --recursive "https://${GH_TOKEN}@github.com/${PLUGIN_INFO[0]}.git" -b "${PLUGIN_INFO[1]:-master}" > /dev/null
          fi
        done

        set +f
      else
        echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Using default plugins embeded with proxy...${COLOR_END}"
      fi

      for PLUGIN in *; do
        if [ -d "${PLUGIN}" ]; then
          pushd "${PLUGIN}" > /dev/null
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install proxy plugin '${PLUGIN}' ...${COLOR_END}"

            npm install > /dev/null

          popd > /dev/null
        fi
      done
    popd > /dev/null
  popd > /dev/null
popd > /dev/null
