#!/bin/bash

if [ "$TRAVIS_BRANCH" -ne "master" ]; then
  echo -e "${COLOR_BLUE}Skipping upload tests result to kuzzle compatibility matrix (test branch must be master)${COLOR_END}"
  exit 0
fi

if [ "$TRAVIS_ALLOW_FAILURE" -eq "false" ]; then
  echo -e "${COLOR_BLUE}Skipping upload tests result to kuzzle compatibility matrix (test allowed to fail)${COLOR_END}"
  exit 0
fi

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

get_google_jwt () {
  local jwt_header=`echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e | tr -d '\n' | tr -d '=' | tr '/+' '_-'`
  local jwt_claim=`echo -n '{\
  "iss":'$1',\
  "scope":"https://www.googleapis.com/auth/spreadsheets",\
  "aud":"https://accounts.google.com/o/oauth2/token",\
  "exp":'$(($(date +%s)+3600))',\
  "iat":'$(date +%s)'}' | openssl base64 -e | tr -d '\n' | tr -d '=' | tr '/+' '_-'`

  local jwt_sign=`echo -n "$jwt_header.$jwt_claim" | openssl sha -sha256 -sign $2 | openssl base64 -e | tr -d '\n' | tr -d '=' | tr '/+' '_-'`

  access_token=$(curl --silent -H "Content-type: application/x-www-form-urlencoded" -X POST "https://accounts.google.com/o/oauth2/token" -d \
  "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=$jwt_header.$jwt_claim.$jwt_sign" | jq -r '.access_token')
}

get_google_jwt "kuzzle-compatibility-matrix@kuzzle-compatibility-matrix.iam.gserviceaccount.com" $SCRIPT_DIR/google.pem
#echo $access_token

spreadsheetId="12ni3IhGVWOh71Didy-sRh4CXZ9Spijxyxbiho-5vPo4"
spreadsheetSheet="Sheet1"

# spreadsheet columns:
# - Build date
build_date=$(date +%s)
# - Travis build ID
build_id=$TRAVIS_BUILD_ID
# - Travis job ID
job_id=$TRAVIS_JOB_ID
# - Travis status
build_status=$TRAVIS_TEST_RESULT
# - kuzzle repository
kuzzle_repository=$(cat /tmp/sandbox/kuzzle/package.json | jq -r ".repository.url")
# - kuzzle branch
kuzzle_branch=$(cd /tmp/sandbox/kuzzle/ && git branch --no-color --no-column | grep "*" | cut -f2- -d' ')
# - kuzzle version
kuzzle_version=$(cat /tmp/sandbox/kuzzle/package.json | jq -r ".version")
# - kuzzle plugins
declare -a kuzzle_plugins

if [ -d "/tmp/sandbox/kuzzle/plugins/enabled/" ]; then
  pushd /tmp/sandbox/kuzzle/plugins/enabled/ > /dev/null
    for PLUGIN in ./*; do
      if [ -d "${PLUGIN}" ]; then
        pushd "${PLUGIN}" > /dev/null
          plugin_name=$(cat ./package.json | jq -r ".name")
          plugin_version=$(cat ./package.json | jq -r ".version")

          kuzzle_plugins=( "${kuzzle_plugins[@]}" "$plugin_name [$plugin_version]" )
        popd > /dev/null
      fi
    done
  popd > /dev/null
fi
kuzzle_plugins=$(IFS="|"; echo "${kuzzle_plugins[*]}")
kuzzle_plugins=${kuzzle_plugins//|/"\n"}

# - proxy repository
proxy_repository=$(cat /tmp/sandbox/kuzzle-proxy/package.json | jq -r ".repository.url")
# - proxy branch
proxy_branch=$(cd /tmp/sandbox/kuzzle-proxy/ && git branch --no-color --no-column | grep "*" | cut -f2- -d' ')
# - proxy version
proxy_version=$(cat /tmp/sandbox/kuzzle-proxy/package.json | jq -r ".version")
# - proxy plugins
declare -a proxy_plugins

if [ -d "/tmp/sandbox/kuzzle-proxy/plugins/enabled/" ]; then
  pushd /tmp/sandbox/kuzzle-proxy/plugins/enabled/ > /dev/null
    for PLUGIN in ./*; do
      if [ -d "${PLUGIN}" ]; then
        pushd "${PLUGIN}" > /dev/null
          plugin_name=$(cat ./package.json | jq -r ".name")
          plugin_version=$(cat ./package.json | jq -r ".version")

          proxy_plugins=( "${proxy_plugins[@]}" "$plugin_name [$plugin_version]" )
        popd > /dev/null
      fi
    done
  popd > /dev/null
fi
proxy_plugins=$(IFS="|"; echo "${proxy_plugins[*]}")
proxy_plugins=${proxy_plugins//|/"\n"}

# - backoffice repository
backoffice_repository=
# - backoffice branch
backoffice_branch=
# - backoffice version
backoffice_version=
# - backoffice embeded sdk version
backoffice_sdk_version=
# - entreprise version ?
is_entreprise=$(echo $proxy_repository | grep "load-balancer" | wc -l)
# - load balancer version
load_balancer_version=
if [ "$is_entreprise" -eq "1" ]; then
  load_balancer_version="$proxy_version ($proxy_branch)"
  proxy_repository=$(cat /tmp/sandbox/kuzzle-proxy/node_modules/kuzzle-proxy/package.json | jq -r ".repository.url")
  proxy_branch=
  proxy_version=$(cat /tmp/sandbox/kuzzle-proxy/node_modules/kuzzle-proxy/package.json | jq -r ".version")
fi
# - cluster plugin version
cluster_plugin_version=
if [ "$is_entreprise" -eq "1" ]; then
  if [ -d "/tmp/sandbox/kuzzle/plugins/enabled/kuzzle-plugin-cluster" ]; then
    cluster_plugin_version=$(cat /tmp/sandbox/kuzzle/plugins/enabled/kuzzle-plugin-cluster/package.json | jq -r ".version")
  else
    cluster_plugin_version="NO CLUSTER MODE"
  fi
fi
# - elasticsearch version
elasticsearch_version=$(curl --silent -XGET http://localhost:9200 | jq -r '.version.number')
# - redis version
redis_version=$({ echo "info server"; echo "quit"; sleep 1;} | telnet localhost 6379 2>/dev/null | grep redis_version | cut -d':' -f2 )
# - node version
node_version=$(node --version)
# - npm version
npm_version=$(npm --version)
# - python version
python_version=$(python --version 2>&1)
# - pm2 version (called twice to ensure that daemon is running)
pm2_version=$(pm2 --version)
pm2_version=$(pm2 --version)
# - os version
os_version=$(lsb_release -d 2> /dev/null | sed 's/:\t/:/' | cut -d ':' -f 2-)
# - kernel version
kernel_version=$(uname -r)
# - docker version
docker_version=$(docker -v)



data='{"range": "Sheet1", "majorDimension": "ROWS", "values": [["'$build_date'", "'$build_id'", "'$job_id'", "'$build_status'", "'$kuzzle_repository'", "'$kuzzle_branch'", "'$kuzzle_version'", "'$kuzzle_plugins'", "'$proxy_repository'", "'$proxy_branch'", "'$proxy_version'", "'$proxy_plugins'", "'$backoffice_repository'", "'$backoffice_branch'", "'$backoffice_version'", "'$backoffice_sdk_version'", "'$is_entreprise'", "'$load_balancer_version'", "'$cluster_plugin_version'", "'$elasticsearch_version'", "'$redis_version'", "'$node_version'", "'$npm_version'", "'$python_version'", "'$pm2_version'", "'$os_version'", "'$kernel_version'", "'$docker_version'"]]}'

echo -e "${COLOR_BLUE}Uploading tests result to kuzzle compatibility matrix${COLOR_END}"
echo $data
curl --silent -H "content-type: application/json" -H "Authorization: Bearer $access_token" -X POST "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$spreadsheetSheet:append?valueInputOption=RAW" -d "$data" > /dev/null
