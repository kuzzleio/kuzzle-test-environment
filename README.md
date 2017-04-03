# Kuzzle testing environment

The main purpose of this repository is to test the stability of a [kuzzle](http://kuzzle.io/) environment

Tests can be run either in a local development environment or on a continuous integration flow

## local development environment

### configuration

```bash
# kuzzle configuration
# kuzzle configuration
KUZZLE_REPO=kuzzleio/kuzzle
KUZZLE_VERSION=master
KUZZLE_COMMON_OBJECT_VERSION=
KUZZLE_PLUGINS=kuzzleio/kuzzle-plugin-auth-passport-local:kuzzleio/kuzzle-plugin-logger
KUZZLE_NODES=1

# kuzzle proxy configuration
PROXY_REPO=kuzzleio/kuzzle-proxy
PROXY_VERSION=master
PROXY_COMMON_OBJECT_VERSION=
PROXY_PLUGINS=

# kuzzle backoffice configuration
BACKOFFICE_REPO=kuzzleio/kuzzle-backoffice
BACKOFFICE_VERSION=2.x
BACKOFFICE_SDK_VERSION=

# load balancer configuration
LB_PROXY_VERSION=
ENABLE_CHAOS_MODE=

# services configuration
ES_VERSION=5
REDIS_VERSION=3

# dependencies configuration
NODE_ENV=development
DEBUG=*
NODE_VERSION=6.9.5
GLOBAL_PM2_VERSION=2.0.19
GCC_VERSION=4.9

# local development environment configuration
GIT_SSL_NO_VERIFY=true
LC_ALL=en_US.UTF-8
```
> **env/common.env** <br />
edit this file to configure your kuzzle environment, *see [environment reference](#environment-reference)*

<br />

```bash
# private configuration
GH_TOKEN=<secret token>

TESTIM_PROJECT=<secret project id>
TESTIM_TOKEN=<secret token>

```
> **env/private.env** *this file is ignored by git*<br />
edit this file to : <br />
* configure your github token if you want to access private repositories
* configure access token from testim if you want to run backoffice end-to-end tests

<br />

### run local sandbox (though docker)

```bash
# launch required services
docker-compose up -d elasticsearch redis

# then launch tests in your sandbox
docker-compose up sandbox

# quick sandbox restart
docker-compose kill sandbox && docker-compose rm -vf sandbox && docker-compose up sandbox
```
> to speed up each installation, you can persist npm cache beetween each run: <br />
- add `- "./.cache/npm:/root/.npm"` to the `services.sandbox.volumes` entry of your `docker-compose.yml` file

### run remote sandbox

```bash
# upload scripts to sandbox
sandbox=127.0.0.1; scp -r ./scripts root@$sandbox:/

# override environment vars
# WARNING: if you have edited your ./env/private.env:
# - you have to append it's content to the remote /etc/environment file
sandbox=127.0.0.1; scp -r ./env/common.env root@$sandbox:/etc/environment

# send kuzzlerc & proxyrc configuration files
sandbox=127.0.0.1; scp -r ./config/* root@$sandbox:/etc/

# install dependencies (packages & services)
sandbox=127.0.0.1; ssh -t root@$sandbox "/scripts/pre-install.sh"

# install kuzzle environment
sandbox=127.0.0.1; ssh -t root@$sandbox "/scripts/install.sh"

# run kuzzle environment functional tests
sandbox=127.0.0.1; ssh -t root@$sandbox "/scripts/run.sh"

# update kuzzle environment sources
sandbox=127.0.0.1; ssh -t root@$sandbox "/scripts/update.sh"

# reset kuzzle environment
sandbox=127.0.0.1; ssh -t root@$sandbox "/scripts/reset.sh"
```

<br />

## continuous integration flow

### configuration


```yml
env:
  global:
    - NODE_VERSION: 6.9.5
    - GLOBAL_PM2_VERSION: 2.0.19
    - GCC_VERSION: 4.9
    - ES_VERSION: 5
    - REDIS_VERSION: 3
  matrix:
    # RC9.6 version
    - KUZZLE_REPO: kuzzleio/kuzzle
      KUZZLE_VERSION: 1.0.0-RC9.6
      PROXY_REPO: kuzzleio/kuzzle-proxy
      PROXY_VERSION: 1.0.0-RC9
      BACKOFFICE_REPO: kuzzleio/kuzzle-backoffice
      BACKOFFICE_VERSION: 2.x
    # RC9.6 entreprise version
    - KUZZLE_REPO: kuzzleio/kuzzle
      KUZZLE_VERSION: 1.0.0-RC9.6
      KUZZLE_PLUGINS: kuzzleio/kuzzle-plugin-auth-passport-local@3.0.4:kuzzleio/kuzzle-plugin-logger@2.0.7:kuzzleio/kuzzle-plugin-cluster@1.x
      BACKOFFICE_REPO: kuzzleio/kuzzle-backoffice
      BACKOFFICE_VERSION: 2.x
      PROXY_REPO: kuzzleio/kuzzle-load-balancer
      PROXY_VERSION: 1.x
      LB_PROXY_VERSION: kuzzleio/kuzzle-proxy@1.0.0-RC9
      "proxy_backend__mode": round-robin
      "kuzzle_plugins__kuzzle-plugin-cluster__privileged": true
      "kuzzle_services__internalBroker__socket": false
      "kuzzle_services__internalBroker__host": 0.0.0.0
      "kuzzle_services__internalBroker__port": 7911
```
> **.travis.yml** <br />
you can add as many as configuration as you need under `env.matrix` dictionary, *see [environment reference](#environment-reference)*

<br />

### schedule execution

- **master** branch is scheduled to be executed on **each day**, it's configuration should contains all stables versions (entreprise and open-source) plus nightly one with allowed faillure enabled


<br />

## environment reference
| Variable | Default | Description |
| ---- | --- | --- |
| KUZZLE_REPO | kuzzleio/kuzzle | kuzzle github source repository |
| KUZZLE_VERSION | master | kuzzle git reference <br /><br /> *can be a branch, tag or commit version* |
| KUZZLE_COMMON_OBJECT_VERSION |  *(optional)* <br /> kuzzleio/kuzzle-common-objects@master | override kuzzle common object version <br /><br /> `<common_object_repo>@<common_object_version>` |
| KUZZLE_PLUGINS | *(optional)* <br /> kuzzleio/kuzzle-plugin-auth-passport-local@master:kuzzleio/kuzzle-plugin-logger@master | override kuzzle server plugin list <br /><br /> `<plugin_1_repo>@<plugin_1_version>:<plugin_2_repo>@<plugin_2_version>`   |
| | | |
| PROXY_REPO | kuzzleio/kuzzle-proxy | proxy github source repository |
| PROXY_VERSION | master | proxy git reference <br /><br /> *can be a branch, tag or commit version* |
| PROXY_COMMON_OBJECT_VERSION | *(optional)* <br /> kuzzleio/kuzzle-common-objects@master | override proxy common object version <br /><br /> `<common_object_repo>@<common_object_version>` |
| PROXY_PLUGINS | *(optional)* <br /> *empty* | override kuzzle proxy plugin list <br /><br /> `<plugin_1_repo>@<plugin_1_version>:<plugin_2_repo>@<plugin_2_version>`
| | | |
| BACKOFFICE_REPO | kuzzleio/kuzzle-backoffice | backoffice github source repository |
| BACKOFFICE_VERSION | master | backoffice git reference <br /><br /> *can be a branch, tag or commit version* |
| BACKOFFICE_SDK_VERSION | *(optional)* <br /> kuzzleio/kuzzle-sdk@master | override kuzzle javascript sdk version <br /><br /> `<sdk_repo>@<sdk_version>` |
| | | |
| LB_PROXY_VERSION | *(optional)* <br /> *empty* | override proxy version for load balancer configurations |
| KUZZLE_NODES | 1 | number of kuzzle core to start |
| ENABLE_CHAOS_MODE | *(optional)* <br /> *empty* | enable chaos mode, wich restart randoly kuzzle node during tests |
| | | |
| ES_VERSION | 5 | define elasticsearch version <br /><br /> *can be a major, minor or patch specific version*
| REDIS_VERSION | 3 | define redis version <br /><br /> *can be a major, minor or patch specific version*
| | | |
| NODE_VERSION | 6.9.5 | define nodejs version |
| GCC_VERSION | 4.9 | define gcc version |
| GLOBAL_PM2_VERSION | *(optional)* <br /> 2.0.19 | override global pm2 version |

<br />

## enhancements
- [x] multiple kuzzle server instances
- [x] enable chaos mode
- [x] allow usage of kuzzle-load-balancer project
- [x] integrate kuzzle backoffice end-to-end tests
- [ ] configure extra optional tests
- [ ] link to release-request process (ci)
