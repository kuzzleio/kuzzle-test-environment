#!/bin/bash
COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

export CC="gcc-$GCC_VERSION"
export CXX="g++-$GCC_VERSION"
GIT_SSL_NO_VERIFY=true

ELASTIC_HOST=${kuzzle_services__db__host:-localhost}
ELASTIC_PORT=${kuzzle_services__db__port:-9200}


if [[ "$TRAVIS" == "true" ]]; then
  ## override path in travis
  ## this is done to remove node bin from nvm in path
  ## nvm was not accesible, so we cant just do
  ## nvm disable
  export PATH="/home/travis/.rvm/gems/ruby-2.2.5/bin:/home/travis/.rvm/gems/ruby-2.2.5@global/bin:/home/travis/.rvm/rubies/ruby-2.2.5/bin:/home/travis/.rvm/bin:/home/travis/bin:/home/travis/.local/bin:/home/travis/.gimme/versions/go1.4.2.linux.amd64/bin:/usr/local/phantomjs/bin:./node_modules/.bin:/usr/local/maven-3.2.5/bin:/usr/local/clang-3.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin"
fi


echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Waiting for elasticsearch to be available${COLOR_END}"
while ! curl -f -s -o /dev/null "http://${ELASTIC_HOST}:${ELASTIC_PORT}"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to elasticsearch at http://${ELASTIC_HOST}:${ELASTIC_PORT}${COLOR_END}"
    sleep 1
done
# create a tmp index just to force the shards to init
curl -XPUT -s -o /dev/null "http://${ELASTIC_HOST}:${ELASTIC_PORT}/%25___tmp"
echo -e "[$(date --rfc-3339 seconds)] - Elasticsearch is up. Waiting for shards to be active (can take a while)${COLOR_END}"
E=$(curl -s "http://${ELASTIC_HOST}:${ELASTIC_PORT}/_cluster/health?wait_for_status=yellow&wait_for_active_shards=1&timeout=60s")
curl -XDELETE -s -o /dev/null "http://${ELASTIC_HOST}:${ELASTIC_PORT}/%25___tmp"

if ! (echo ${E} | grep -E '"status":"(yellow|green)"' > /dev/null); then
    echo -e "[$(date --rfc-3339 seconds)] - Could not connect to elasticsearch in time. Aborting...${COLOR_END}"
    exit 1
fi




echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle environment installation...${COLOR_END}"
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Setting up npm...${COLOR_END}"
echo -e

if [ -d "/tmp/.npm-global" ]; then
  rm -rf "/tmp/.npm-global"
fi
mkdir "/tmp/.npm-global"

npm cache clean --force

npm config set progress false
npm config set strict-ssl false
npm config set prefix '/tmp/.npm-global'

export PATH="/tmp/.npm-global/bin:$PATH"




echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install pm2...${COLOR_END}"
echo -e

npm uninstall -g pm2 || true

if [[ "${GLOBAL_PM2_VERSION}" == "" ]]; then
  npm install -g pm2
else
  npm install -g pm2@${GLOBAL_PM2_VERSION}
fi

pm2 flush






echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install projects...${COLOR_END}"
echo -e

if [ ! -d "/tmp/sandbox" ]; then
  mkdir -p "/tmp/sandbox"
fi

pushd "/tmp/sandbox" &>/dev/null

  echo -e
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle proxy '${PROXY_VERSION}' ...${COLOR_END}"
  echo -e

  if [ -d "kuzzle-proxy" ]; then
    rm -rf ./kuzzle-proxy
  fi

  if [[ "${PROXY_PLUGINS}" == "" ]]; then
    git clone --recursive "https://${GH_TOKEN}@github.com/${PROXY_REPO}.git" -b "${PROXY_VERSION}" kuzzle-proxy
  else
    git clone "https://${GH_TOKEN}@github.com/${PROXY_REPO}.git" -b "${PROXY_VERSION}" kuzzle-proxy
  fi

  pushd kuzzle-proxy &>/dev/null

    npm install

    if [[ "${PROXY_COMMON_OBJECT_VERSION}" != "" ]]; then
      echo -e
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install proxy common objects '${PROXY_COMMON_OBJECT_VERSION}' ...${COLOR_END}"
      echo -e

      npm uninstall kuzzle-common-object || true
      npm install "${PROXY_COMMON_OBJECT_VERSION}"
    fi

    if [ -d "plugins/enabled" ]; then
      pushd plugins/enabled &>/dev/null

        if [[ "${PROXY_PLUGINS}" != "" ]]; then
          echo -e
          echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle proxy plugin list overrided${COLOR_END}"

          rm -rf ./*

          set -f

          PLUGINS=(${PROXY_PLUGINS//:/ })

          for i in "${!PLUGINS[@]}"; do
            if [[ "${PLUGINS[i]}" != "" ]]; then
              PLUGIN_INFO=(${PLUGINS[i]//#/ })

              echo -e
              echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading proxy plugin '${PLUGIN_INFO[0]}'@'${PLUGIN_INFO[1]:-master}' ...${COLOR_END}"
              echo -e
              git clone --recursive "https://${GH_TOKEN}@github.com/${PLUGIN_INFO[0]}.git" -b "${PLUGIN_INFO[1]:-master}"
            fi
          done

          set +f
        fi

        for PLUGIN in *; do
          if [ -d "${PLUGIN}" ]; then
            pushd "${PLUGIN}" &>/dev/null
              echo -e
              echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install proxy plugin '${PLUGIN}' ...${COLOR_END}"
              echo -e

              npm install

            popd &>/dev/null
          fi
        done
      popd &>/dev/null
    fi

    pm2 start --silent ./docker-compose/config/pm2.json

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle proxy '${PROXY_VERSION}' started ...${COLOR_END}"
    echo -e
  popd &>/dev/null







  echo -e
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle '${KUZZLE_VERSION}' ...${COLOR_END}"
  echo -e

  if [ -d "kuzzle" ]; then
    rm -rf ./kuzzle
  fi

  if [[ "${KUZZLE_PLUGINS}" == "" ]]; then
    git clone --recursive "https://${GH_TOKEN}@github.com/${KUZZLE_REPO}.git" -b "${KUZZLE_VERSION}" kuzzle
  else
    git clone "https://${GH_TOKEN}@github.com/${KUZZLE_REPO}.git" -b "${KUZZLE_VERSION}" kuzzle
  fi

  pushd kuzzle &>/dev/null

    npm install

    if [[ "${KUZZLE_COMMON_OBJECT_VERSION}" != "" ]]; then
      echo -e
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Override kuzzle common objects '${KUZZLE_COMMON_OBJECT_VERSION}' ...${COLOR_END}"
      echo -e

      npm uninstall kuzzle-common-object || true
      npm install "${KUZZLE_COMMON_OBJECT_VERSION}"
    fi

    if [ -d "plugins/enabled" ]; then
      pushd plugins/enabled &>/dev/null

        if [[ "${KUZZLE_PLUGINS}" != "" ]]; then
          echo -e
          echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle plugin list overrided${COLOR_END}"

          rm -rf ./*

          set -f

          PLUGINS=(${KUZZLE_PLUGINS//:/ })

          for i in "${!PLUGINS[@]}"; do
            if [[ "${PLUGINS[i]}" != "" ]]; then
              PLUGIN_INFO=(${PLUGINS[i]//#/ })

              echo -e
              echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Downloading kuzzle plugin '${PLUGIN_INFO[0]}'@'${PLUGIN_INFO[1]:-master}' ...${COLOR_END}"
              echo -e
              git clone --recursive "https://${GH_TOKEN}@github.com/${PLUGIN_INFO[0]}.git" -b "${PLUGIN_INFO[1]:-master}"
            fi
          done

          set +f
        fi

        for PLUGIN in *; do
          if [ -d "${PLUGIN}" ]; then
            pushd "${PLUGIN}" &>/dev/null
              echo -e
              echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle plugin '${PLUGIN}' ...${COLOR_END}"
              echo -e

              npm install
            popd &>/dev/null
          fi
        done
      popd &>/dev/null
    fi

    pm2 start --silent ./docker-compose/config/pm2.json

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle '${KUZZLE_VERSION}' started ...${COLOR_END}"
    echo -e
  popd &>/dev/null

popd &>/dev/null


echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Waiting for kuzzle to be available${COLOR_END}"
while ! curl -f -s -o /dev/null "http://localhost:7512"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to kuzzle at http://localhost:7512${COLOR_END}"
    sleep 1
done
