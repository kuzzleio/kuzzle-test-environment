#!/bin/bash

echo "=> run"

pushd "$HOME" &>/dev/null
  pushd kuzzle-proxy &>/dev/null
  npm run test
  popd &>/dev/null

  pushd kuzzle &>/dev/null
  npm run test
  popd &>/dev/null
popd &>/dev/null
