#!/bin/bash
set -ex

apt-get update
apt-get install -yq --no-install-suggests --no-install-recommends --force-yes build-essential curl git gcc-"$GCC_VERSION" g++-"$GCC_VERSION" gdb python openssl

curl -kO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz"
tar -xf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1
rm "node-v$NODE_VERSION-linux-x64.tar.gz"
ln -s /usr/local/bin/node /usr/local/bin/nodejs

command -v docker || (curl -fsSL https://get.docker.com/ | sh)

docker run -d --name elasticsearch:"${ES_VERSION}" -p 9200:9200 elasticsearch
docker run -d --name redis:"${REDIS_VERSION}" -p 6379:6379 redis