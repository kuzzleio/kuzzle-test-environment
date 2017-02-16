#!/bin/bash
set -e

ELASTIC_HOST=${kuzzle_services__db__host:-localhost}
ELASTIC_PORT=${kuzzle_services__db__port:-9200}
if [[ $TRAVIS -eq "true" ]]; then
  echo "travis"
fi

PATH="/tmp/.npm-global/bin:/home/travis/.rvm/gems/ruby-2.2.5/bin:/home/travis/.rvm/gems/ruby-2.2.5@global/bin:/home/travis/.rvm/rubies/ruby-2.2.5/bin:/home/travis/.rvm/bin:/home/travis/bin:/home/travis/.local/bin:/home/travis/.gimme/versions/go1.4.2.linux.amd64/bin:/usr/local/phantomjs/bin:./node_modules/.bin:/usr/local/maven-3.2.5/bin:/usr/local/clang-3.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin"
NPM_CONFIG_PREFIX=/tmp/.npm-global

npm config set prefix '/tmp/.npm-global'

if [ -d "/tmp/.npm-global" ]; then
  rm -rf "/tmp/.npm-global"
fi
mkdir "/tmp/.npm-global"

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_LBLUE="\e[94m"
COLOR_YELLOW="\e[33m"
COLOR_LYELLOW="\e[93m"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LYELLOW}Waiting for elasticsearch to be available$COLOR_END"
while ! curl -f -s -o /dev/null "http://$ELASTIC_HOST:$ELASTIC_PORT"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to elasticsearch at http://$ELASTIC_HOST:$ELASTIC_PORT$COLOR_END"
    sleep 1
done
# create a tmp index just to force the shards to init
curl -XPUT -s -o /dev/null "http://$ELASTIC_HOST:$ELASTIC_PORT/%25___tmp"
echo -e "[$(date --rfc-3339 seconds)] - Elasticsearch is up. Waiting for shards to be active (can take a while)$COLOR_END"
E=$(curl -s "http://$ELASTIC_HOST:$ELASTIC_PORT/_cluster/health?wait_for_status=yellow&wait_for_active_shards=1&timeout=60s")
curl -XDELETE -s -o /dev/null "http://$ELASTIC_HOST:$ELASTIC_PORT/%25___tmp"

if ! (echo ${E} | grep -E '"status":"(yellow|green)"' > /dev/null); then
    echo -e "[$(date --rfc-3339 seconds)] - Could not connect to elasticsearch in time. Aborting...$COLOR_END"
    exit 1
fi

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting environment installation...$COLOR_END"



echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install dependencies...$COLOR_END"
echo -e

which node
node --version
echo $PATH

npm cache clean --force
npm install npm -g
npm config set prefix '/tmp/.npm-global'

npm set progress=false

npm uninstall -g pm2 || true
npm install -g pm2@${GLOBAL_PM2_VERSION}

pm2 flush

echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install projects...$COLOR_END"
echo -e

if [ ! -d "/tmp/sandbox" ]; then
  mkdir -p "/tmp/sandbox"
fi

pushd "/tmp/sandbox" &>/dev/null

  echo -e
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Install kuzzle proxy '$PROXY_VERSION' ...$COLOR_END"
  echo -e

  if [ -d "kuzzle-proxy" ]; then
    rm -rf ./kuzzle-proxy
  fi

  git clone --recursive "http://github.com/${PROXY_REPO}.git" -b "$PROXY_VERSION"

  pushd kuzzle-proxy &>/dev/null
    npm install

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install proxy common objects '$PROXY_COMMON_OBJECT_VERSION' ...$COLOR_END"
    echo -e

    npm uninstall kuzzle-common-object
    npm install "$PROXY_COMMON_OBJECT_VERSION"

    pushd plugins/enabled &>/dev/null
      for D in *; do
        if [ -d "${D}" ]; then
          pushd "$D" &>/dev/null
            echo -e
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install proxy plugin '$D' ...$COLOR_END"
            echo -e

            npm install

            echo -e
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install proxy common objects '$PROXY_COMMON_OBJECT_VERSION' for plugin '$D'...$COLOR_END"
            echo -e

            npm uninstall kuzzle-common-object
            npm install "$PROXY_COMMON_OBJECT_VERSION"
          popd &>/dev/null
        fi
      done
    popd &>/dev/null

    pm2 start --silent ./docker-compose/config/pm2.json

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Kuzzle proxy '$PROXY_VERSION' started ...$COLOR_END"
    echo -e
  popd &>/dev/null



  echo -e
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Install kuzzle '$KUZZLE_VERSION' ...$COLOR_END"
  echo -e

  if [ -d "kuzzle" ]; then
    rm -rf ./kuzzle
  fi

  git clone --recursive https://github.com/"$KUZZLE_REPO".git -b "$KUZZLE_VERSION"

  pushd kuzzle &>/dev/null
    npm install

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle common objects '$KUZZLE_COMMON_OBJECT_VERSION' ...$COLOR_END"
    echo -e

    npm uninstall kuzzle-common-object
    npm install "$KUZZLE_COMMON_OBJECT_VERSION"

    pushd plugins/enabled &>/dev/null
      for D in *; do
        if [ -d "${D}" ]; then
          pushd "$D" &>/dev/null
            echo -e
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle plugin '$D' ...$COLOR_END"
            echo -e

            npm install

            echo -e
            echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle common objects '$PROXY_COMMON_OBJECT_VERSION' for plugin '$D'...$COLOR_END"
            echo -e

            npm uninstall kuzzle-common-object
            npm install "$PROXY_COMMON_OBJECT_VERSION"
          popd &>/dev/null
        fi
      done
    popd &>/dev/null

    pm2 start --silent ./docker-compose/config/pm2.json

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Kuzzle '$KUZZLE_VERSION' started ...$COLOR_END"
    echo -e
  popd &>/dev/null

popd &>/dev/null


echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LYELLOW}Waiting for kuzzle to be available$COLOR_END"
while ! curl -f -s -o /dev/null "http://localhost:7512"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to kuzzle at http://localhost:7512$COLOR_END"
    sleep 1
done
