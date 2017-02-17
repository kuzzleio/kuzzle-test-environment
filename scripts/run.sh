#!/bin/bash
set -e

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

if [[ $TRAVIS -eq "true" ]]; then
  ## override path in travis
  ## this is done to remove node bin from nvm in path
  ## nvm was not accesible, so we cant just do 
  ## nvm disable
  export PATH="/tmp/.npm-global/bin:/home/travis/.rvm/gems/ruby-2.2.5/bin:/home/travis/.rvm/gems/ruby-2.2.5@global/bin:/home/travis/.rvm/rubies/ruby-2.2.5/bin:/home/travis/.rvm/bin:/home/travis/bin:/home/travis/.local/bin:/home/travis/.gimme/versions/go1.4.2.linux.amd64/bin:/usr/local/phantomjs/bin:./node_modules/.bin:/usr/local/maven-3.2.5/bin:/usr/local/clang-3.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin"
fi

echo -e
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Runing tests...$COLOR_END"
echo -e

pushd "/tmp/sandbox" &>/dev/null
  pushd kuzzle-proxy &>/dev/null
    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Runing kuzzle-proxy tests...$COLOR_END"
    echo -e

    npm run test

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}kuzzle-proxy tests ok !$COLOR_END"
    echo -e
  popd &>/dev/null

  pushd kuzzle &>/dev/null
    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Runing kuzzle tests...$COLOR_END"
    echo -e

    npm run test

    echo -e
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}kuzzle tests ok !$COLOR_END"
    echo -e
  popd &>/dev/null
popd &>/dev/null
