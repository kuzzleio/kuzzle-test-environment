#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting functional testing suite...$COLOR_END"

if [[ $ENABLE_CHAOS_MODE == "true" ]]; then
  bash "$SCRIPT_DIR/run-chaos.sh" &
fi

pushd "/tmp/sandbox" &>/dev/null
  # run e2e proxy tests if exists
  pushd kuzzle-proxy &>/dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle-proxy tests...$COLOR_END"

    if [[ $(npm run | grep functional-testing) ]]; then
      bash -c "${SCRIPT_DIR}/reset.sh"

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle-proxy functional tests...$COLOR_END"

      npm run functional-testing

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}kuzzle-proxy functional tests ok !$COLOR_END"
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Skipping kuzzle-proxy, no functional tests found.$COLOR_END"
    fi

  popd &>/dev/null

  # run e2e kuzzle tests if exists
  pushd kuzzle &>/dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle tests...$COLOR_END"

    if [[ $(npm run | grep functional-testing) ]]; then
      bash -c "${SCRIPT_DIR}/reset.sh"

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle functional tests...$COLOR_END"

      npm run functional-testing

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}kuzzle tests functional ok !$COLOR_END"
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Skipping kuzzle, no functional tests found.$COLOR_END"
    fi
  popd &>/dev/null

  # run e2e kuzzle-backoffice tests with chrome & firefox
  pushd kuzzle-backoffice &>/dev/null
    bash -c "${SCRIPT_DIR}/reset.sh"

    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle backoffice tests (chrome)...$COLOR_END"

    docker inspect "testim" &>/dev/null && sh -c "docker kill testim || true" && sh -c "docker rm -vf testim || true"

    docker run --network="bridge" \
      --name "testim" \
      --link "hub:hub" \
      --link "proxy:proxy" \
      --link "backoffice:backoffice" \
      --volume "/tmp/sandbox/kuzzle-backoffice/test/e2e/run-test.sh:/opt/run-test.sh" \
      --volume "/tmp/sandbox/kuzzle-backoffice/test/e2e/config-file.js:/opt/config-file.js" \
      -e "TESTIM_PROJECT=$TESTIM_PROJECT" \
      -e "TESTIM_TOKEN=$TESTIM_TOKEN" \
      -e "BROWSER=chrome" \
      -ti \
      tests/kuzzle-base \
        bash -c 'chmod 755 /opt/run-test.sh && /opt/run-test.sh'

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle backoffice tests ended (chrome)...$COLOR_END"

      bash -c "${SCRIPT_DIR}/reset.sh"

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle backoffice tests (firefox)...$COLOR_END"

      docker inspect "testim" &>/dev/null && sh -c "docker kill testim || true" && sh -c "docker rm -vf testim || true"

      docker run --network="bridge" \
        --name "testim" \
        --link "hub:hub" \
        --link "proxy:proxy" \
        --link "backoffice:backoffice" \
        --volume "/tmp/sandbox/kuzzle-backoffice/test/e2e/run-test.sh:/opt/run-test.sh" \
        --volume "/tmp/sandbox/kuzzle-backoffice/test/e2e/config-file.js:/opt/config-file.js" \
        -e "TESTIM_PROJECT=$TESTIM_PROJECT" \
        -e "TESTIM_TOKEN=$TESTIM_TOKEN" \
        -e "BROWSER=firefox" \
        -ti \
        tests/kuzzle-base \
          bash -c 'chmod 755 /opt/run-test.sh && /opt/run-test.sh'

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle backoffice tests ended (firefox)...$COLOR_END"

  popd &>/dev/null
popd &>/dev/null
