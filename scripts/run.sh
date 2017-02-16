#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_LBLUE="\e[94m"
COLOR_YELLOW="\e[33m"
COLOR_LYELLOW="\e[93m"

if [[ $TRAVIS -eq "true" ]]; then
  export PATH="/tmp/.npm-global/bin:/home/travis/.rvm/gems/ruby-2.2.5/bin:/home/travis/.rvm/gems/ruby-2.2.5@global/bin:/home/travis/.rvm/rubies/ruby-2.2.5/bin:/home/travis/.rvm/bin:/home/travis/bin:/home/travis/.local/bin:/home/travis/.gimme/versions/go1.4.2.linux.amd64/bin:/usr/local/phantomjs/bin:./node_modules/.bin:/usr/local/maven-3.2.5/bin:/usr/local/clang-3.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin"
fi

echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Runing tests...$COLOR_END"
echo -e

echo -e "-> ${COLOR_BLUE}node version:$COLOR_END"
node --version

echo -e "-> ${COLOR_BLUE}npm version:$COLOR_END"
npm --version

echo -e "-> ${COLOR_BLUE}pm2 version:$COLOR_END"
pm2 --version

echo -e "-> ${COLOR_BLUE}python version:$COLOR_END"
python --version

echo -e "-> ${COLOR_BLUE}gcc version:$COLOR_END"
gcc --version

echo -e "-> ${COLOR_BLUE}build env:$COLOR_END"
printenv

pushd "/tmp/sandbox" &>/dev/null
  pushd kuzzle-proxy &>/dev/null
    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Runing kuzzle-proxy tests...$COLOR_END"
    echo -e

    npm run test

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}kuzzle-proxy tests ok !$COLOR_END"
    echo -e
  popd &>/dev/null

  pushd kuzzle &>/dev/null
    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}Runing kuzzle tests...$COLOR_END"
    echo -e

    npm run test

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_LBLUE}kuzzle tests ok !$COLOR_END"
    echo -e
  popd &>/dev/null
popd &>/dev/null
