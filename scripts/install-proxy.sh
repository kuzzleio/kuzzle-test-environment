#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

if [ -d "kuzzle-proxy" ]; then
  rm -rf ./kuzzle-proxy
fi

if [[ "${PROXY_PLUGINS}" == "" ]]; then
  git clone --recursive "https://${GH_TOKEN}@github.com/${PROXY_REPO}.git" -b "${PROXY_VERSION}" kuzzle-proxy > /dev/null
else
  git clone "https://${GH_TOKEN}@github.com/${PROXY_REPO}.git" -b "${PROXY_VERSION}" kuzzle-proxy > /dev/null
fi

pushd kuzzle-proxy > /dev/null

  npm install > /dev/null

  if [[ "${PROXY_COMMON_OBJECT_VERSION}" != "" ]]; then
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Override proxy common objects '${PROXY_COMMON_OBJECT_VERSION}' ...${COLOR_END}"

    npm uninstall kuzzle-common-object > /dev/null || true
    npm install "${PROXY_COMMON_OBJECT_VERSION}" > /dev/null
  else
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Using default common objects embeded with proxy...${COLOR_END}"
  fi

  if [[ "${LB_PROXY_VERSION}" != "" ]]; then
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Override load balancer proxy version '${LB_PROXY_VERSION}' ...${COLOR_END}"

    npm uninstall kuzzle-proxy > /dev/null || true
    npm install "${LB_PROXY_VERSION}" > /dev/null
  fi

  if [ ! -d "plugins/enabled" ]; then
    mkdir -p "plugins/enabled"
  fi

  pushd plugins/enabled > /dev/null

    if [[ "${PROXY_PLUGINS}" != "" ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle proxy plugin list overrided${COLOR_END}"

      rm -rf ./*

      set -f

      PLUGINS=(${PROXY_PLUGINS//:/ })

      for i in "${!PLUGINS[@]}"; do
        if [[ "${PLUGINS[i]}" != "" ]]; then
          PLUGIN_INFO=(${PLUGINS[i]//#/ })

          echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading proxy plugin '${PLUGIN_INFO[0]}'@'${PLUGIN_INFO[1]:-master}' ...${COLOR_END}"
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
