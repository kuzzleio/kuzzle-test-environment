#!/bin/bash

#-------------------------------------------------------------------------------
#
#   Kuzzle end-to-end test sandbox
#
#   Script aim: run end-to-end test
#   - start chaos mode if needed
#   - run proxy end-to-end tests if exists
#   - run kuzzle core end-to-end tests if exists
#   - run backoffice end-to-end
#
#-------------------------------------------------------------------------------

set -E

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

SANDBOX_DIR="/tmp/sandbox"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting functional testing suite...$COLOR_END"

if [[ "${ENABLE_CHAOS_MODE}" == "true" ]]; then
  bash "${SCRIPT_DIR}/parts/run-chaos.sh" &
fi

pushd "${SANDBOX_DIR}" &>/dev/null
  # run e2e proxy tests if exists
  pushd kuzzle-proxy &>/dev/null
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle-proxy tests...$COLOR_END"

    if [[ $(npm run | grep functional-testing) ]]; then

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle-proxy functional tests...$COLOR_END"
      bash -c "${SCRIPT_DIR}/parts/reset-kuzzle.sh"

      echo "PROXY TESTS" > /tmp/sandbox-status
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

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle functional tests...$COLOR_END"
      bash -c "${SCRIPT_DIR}/parts/reset-kuzzle.sh"

      echo "KUZZLE TESTS" > /tmp/sandbox-status
      npm run functional-testing

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}kuzzle tests functional ok !$COLOR_END"
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Skipping kuzzle, no functional tests found.$COLOR_END"
    fi
  popd &>/dev/null

  # run e2e kuzzle-backoffice tests with chrome & firefox
  pushd kuzzle-backoffice &>/dev/null

    if [[ "${TESTIM_PROJECT}" == "" ]] || [[ "${TESTIM_TOKEN}" == "" ]]; then
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Skipping backoffice tests, you need to define TESTIM_PROJECT and TESTIM_TOKEN environment variables.$COLOR_END"
    else
      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle backoffice tests (chrome)...$COLOR_END"
      bash -c "${SCRIPT_DIR}/parts/reset-kuzzle.sh"

      docker inspect "testim" &>/dev/null && sh -c "docker kill testim || true" && sh -c "docker rm -vf testim || true"

      echo "BACKOFFICE CHROME TESTS" > /tmp/sandbox-status
      docker run --network="bridge" \
        --name "testim" \
        --link "hub:hub" \
        --link "proxy:proxy" \
        --link "backoffice:backoffice" \
        --volume "${SANDBOX_DIR}/kuzzle-backoffice/test/e2e/run-test.sh:/opt/run-test.sh" \
        --volume "${SANDBOX_DIR}/kuzzle-backoffice/test/e2e/config-file.js:/opt/config-file.js" \
        -e "TESTIM_PROJECT=${TESTIM_PROJECT}" \
        -e "TESTIM_TOKEN=${TESTIM_TOKEN}" \
        -e "BROWSER=chrome" \
        -ti \
        tests/kuzzle-base:raw \
          bash -c 'chmod 755 /opt/run-test.sh && /opt/run-test.sh'

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle backoffice tests ended (chrome)...$COLOR_END"
      bash -c "${SCRIPT_DIR}/parts/reset-kuzzle.sh"

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Running kuzzle backoffice tests (firefox)...$COLOR_END"

      docker inspect "testim" &>/dev/null && sh -c "docker kill testim || true" && sh -c "docker rm -vf testim || true"

      echo "BACKOFFICE FIREFOX TESTS" > /tmp/sandbox-status
      docker run --network="bridge" \
        --name "testim" \
        --link "hub:hub" \
        --link "proxy:proxy" \
        --link "backoffice:backoffice" \
        --volume "${SANDBOX_DIR}/kuzzle-backoffice/test/e2e/run-test.sh:/opt/run-test.sh" \
        --volume "${SANDBOX_DIR}/kuzzle-backoffice/test/e2e/config-file.js:/opt/config-file.js" \
        -e "TESTIM_PROJECT=${TESTIM_PROJECT}" \
        -e "TESTIM_TOKEN=${TESTIM_TOKEN}" \
        -e "BROWSER=firefox" \
        -ti \
        tests/kuzzle-base:raw \
          bash -c 'chmod 755 /opt/run-test.sh && /opt/run-test.sh'

      echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle backoffice tests ended (firefox)...$COLOR_END"
    fi
  popd &>/dev/null
popd &>/dev/null

echo "SUCCESS" > /tmp/sandbox-status
