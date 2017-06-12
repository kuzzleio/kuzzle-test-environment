#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

LSB_DIST=""
DIST_VERSION=""

SANDBOX_DIR="/tmp/sandbox"
SANDBOX_ENDPOINT="http://localhost:7512/"

KUZZLE_NODES=${KUZZLE_NODES:-1}

KUZZLE_EXTRA_ENV="$KUZZLE_EXTRA_ENV kuzzle_services__db__client__host=http://elasticsearch:9200"
KUZZLE_EXTRA_ENV="$KUZZLE_EXTRA_ENV kuzzle_services__internalCache__node__host=redis"
KUZZLE_EXTRA_ENV="$KUZZLE_EXTRA_ENV kuzzle_services__memoryStorage__node__host=redis"
KUZZLE_EXTRA_ENV="$KUZZLE_EXTRA_ENV kuzzle_services__proxyBroker__host=proxy"

CHAOS_LOG="${SANDBOX_DIR}/chaos_mode.log"

ELASTIC_HOST=${kuzzle_services__db__client__host:-"http://elasticsearch:9200"}

if command -v lsb_release > /dev/null 2>&1; then
  LSB_DIST="$(lsb_release -si)"
fi
if [ -z "${LSB_DIST}" ] && [ -r /etc/lsb-release ]; then
  LSB_DIST="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "${LSB_DIST}" ] && [ -r /etc/debian_version ]; then
  LSB_DIST='debian'
fi
LSB_DIST="$(echo "${LSB_DIST}" | tr '[:upper:]' '[:lower:]')"

case "${LSB_DIST}" in
  ubuntu)
    if command -v lsb_release > /dev/null 2>&1; then
      DIST_VERSION="$(lsb_release --codename | cut -f2)"
    fi
    if [ -z "${DIST_VERSION}" ] && [ -r /etc/lsb-release ]; then
      DIST_VERSION="$(. /etc/lsb-release && echo "${DISTRIB_CODENAME}")"
    fi
  ;;

  debian)
    DIST_VERSION="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
    case "${DIST_VERSION}" in
      9)
        DIST_VERSION="stretch"
      ;;
      8)
        DIST_VERSION="jessie"
      ;;
      7)
        DIST_VERSION="wheezy"
      ;;
    esac
  ;;
esac
