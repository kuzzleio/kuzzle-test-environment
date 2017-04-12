#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading kuzzle '${KUZZLE_REPO}@${KUZZLE_VERSION}' ...${COLOR_END}"


pushd /tmp/sandbox/ > /dev/null
  if [ -d "kuzzle" ]; then
    rm -rf ./kuzzle
  fi

  if [[ "${KUZZLE_PLUGINS}" == "" ]]; then
    git clone --recursive "https://${GH_TOKEN}@github.com/${KUZZLE_REPO}.git" -b "${KUZZLE_VERSION}" kuzzle > /dev/null
  else
    git clone "https://${GH_TOKEN}@github.com/${KUZZLE_REPO}.git" -b "${KUZZLE_VERSION}" kuzzle > /dev/null
  fi

  pushd kuzzle > /dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle dependencies ...${COLOR_END}"
    npm install > /dev/null

    if [[ "${KUZZLE_COMMON_OBJECT_VERSION}" != "" ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Override kuzzle common objects '${KUZZLE_COMMON_OBJECT_VERSION}' ...${COLOR_END}"

      npm uninstall kuzzle-common-object > /dev/null || true
      npm install "${KUZZLE_COMMON_OBJECT_VERSION/@/#}" > /dev/null
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Using default common objects embeded with kuzzle...${COLOR_END}"
    fi


    if [ ! -d "plugins/enabled" ]; then
      mkdir -p "plugins/enabled"
    fi

    pushd plugins/enabled > /dev/null
      if [[ "${KUZZLE_PLUGINS}" != "" ]]; then
        echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle plugin list overrided${COLOR_END}"

        rm -rf ./*

        set -f

        OIFS=$IFS;
        IFS=":";
        KUZZLE_PLUGINS=($KUZZLE_PLUGINS);
        IFS=$OIFS;

        for ((i=0; i<${#KUZZLE_PLUGINS[@]}; ++i)); do
          if [[ "${KUZZLE_PLUGINS[$i]}" != "" ]]; then

            OIFS=$IFS;
            IFS="@";
            PLUGIN_INFO=(${KUZZLE_PLUGINS[$i]});
            IFS=$OIFS;

            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading kuzzle plugin '${PLUGIN_INFO[0]}@${PLUGIN_INFO[1]:-master}' ...${COLOR_END}"
            git clone --recursive "https://${GH_TOKEN}@github.com/${PLUGIN_INFO[0]}.git" -b "${PLUGIN_INFO[1]:-master}" > /dev/null
          fi
        done

        set +f
      else
        echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Using default plugins embeded with kuzzle...${COLOR_END}"
      fi

      for PLUGIN in ./*; do
        if [ -d "${PLUGIN}" ]; then
          pushd "${PLUGIN}" > /dev/null
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle plugin '${PLUGIN}' ...${COLOR_END}"

            npm install > /dev/null
          popd > /dev/null
        fi
      done
    popd > /dev/null
  popd > /dev/null
popd > /dev/null
