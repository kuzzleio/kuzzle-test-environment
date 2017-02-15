#!/bin/bash

wORKING_DIR='/home/node'

echo "=> run"

pushd "$wORKING_DIR" &>/dev/null
  pushd kuzzle-proxy &>/dev/null
  npm run test
  popd &>/dev/null

  pushd kuzzle &>/dev/null
  npm run test
  popd &>/dev/null
popd &>/dev/null
