#!/bin/bash
COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

SCRIPT_DIR=$(echo "$(pwd)/scripts" | sed "s#//#/#g")

export CC="gcc-$GCC_VERSION"
export CXX="g++-$GCC_VERSION"
export PATH="/tmp/.npm-global/bin:$PATH"

GIT_SSL_NO_VERIFY=true

if [[ "$TRAVIS" == "true" ]]; then
  ## override path in travis
  ## this is done to remove node bin from nvm in path
  ## nvm was not accesible, so we cant just do
  ## nvm disable
  export PATH="/home/travis/.rvm/gems/ruby-2.2.5/bin:/home/travis/.rvm/gems/ruby-2.2.5@global/bin:/home/travis/.rvm/rubies/ruby-2.2.5/bin:/home/travis/.rvm/bin:/home/travis/bin:/home/travis/.local/bin:/home/travis/.gimme/versions/go1.4.2.linux.amd64/bin:/usr/local/phantomjs/bin:./node_modules/.bin:/usr/local/maven-3.2.5/bin:/usr/local/clang-3.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin"
fi


echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle environment installation...${COLOR_END}"

docker run \
  --network="bridge" \
  --name "kuzzle-base" \
  -e "GCC_VERSION=$GCC_VERSION" \
  -e "NODE_VERSION=$NODE_VERSION" \
  --volume "/scripts:$SCRIPT_DIR" \
  debian:jessie \
    bash -c 'bash /scripts/install-deps.sh'

docker commit \
  --change 'WORKDIR /tmp/sandbox/app' \
  kuzzle-base \
  tests/kuzzle-base

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install projects...${COLOR_END}"

if [ ! -d "/tmp/sandbox" ]; then
  mkdir -p "/tmp/sandbox"
fi

pushd "/tmp/sandbox" > /dev/null
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle proxy '${PROXY_REPO}@${PROXY_VERSION}' ...${COLOR_END}"

  bash "$SCRIPT_DIR/install-proxy.sh"

  pushd "kuzzle-proxy" > /dev/null
    # pm2 start --silent ./docker-compose/config/pm2.json  > /dev/null
    set -x
    docker run --network="bridge" \
               --detach \
               --name "proxy" \
               -e "proxy_backend__mode=round-robin" \
               --volume "/tmp/sandbox/kuzzle-proxy:/tmp/sandbox/app" \
               --publish "7512:7512" \
               tests/kuzzle-base \
                 bash -c 'pm2 start --silent ./docker-compose/config/pm2.json && tail -f /dev/null'
    set +x

    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle proxy '${PROXY_VERSION}' started ...${COLOR_END}"
  popd > /dev/null

  echo -e

  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install kuzzle '${KUZZLE_REPO}@${KUZZLE_VERSION}' ...${COLOR_END}"

  bash "$SCRIPT_DIR/install-kuzzle.sh"

  pushd "kuzzle" > /dev/null
    #pm2 start --silent ./docker-compose/config/pm2.json > /dev/null

    for i in `seq 1 ${KUZZLE_NODES:-1}`;
    do
        echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting ${i}/${KUZZLE_NODES:-1} kuzzle ...${COLOR_END}"
        docker run --network="bridge" \
                   --detach \
                   --name "kuzzle_${i}" \
                   --link "proxy:proxy" \
                   --link "elasticsearch:elasticsearch" \
                   --link "redis:redis" \
                   -e "kuzzle_services__db__host=elasticsearch" \
                   -e "kuzzle_services__internalCache__node__host=redis" \
                   -e "kuzzle_services__memoryStorage__node__host=redis" \
                   -e "kuzzle_services__proxyBroker__host=proxy" \
                   -e "kuzzle_plugins__kuzzle-plugin-cluster__privileged=true" \
                   --volume "/tmp/sandbox/kuzzle:/tmp/sandbox/app" \
                   tests/kuzzle-base \
                     bash -c 'pm2 start --silent ./docker-compose/config/pm2.json && tail -f /dev/null'
    done

    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle '${KUZZLE_VERSION}' started ...${COLOR_END}"
  popd > /dev/null
popd > /dev/null

echo -e


echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Waiting for kuzzle to be available${COLOR_END}"
while ! curl -f -s -o /dev/null "http://localhost:7512"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to kuzzle at http://localhost:7512${COLOR_END}"
    sleep 1
done
