#!/bin/bash
set -ex

apt-get update
apt-get install -yq --no-install-suggests --no-install-recommends --force-yes build-essential curl git g++ gdb python openssl

curl -kO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz"
tar -xvf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1
rm "node-v$NODE_VERSION-linux-x64.tar.gz"
ln -s /usr/local/bin/node /usr/local/bin/nodejs

which node
