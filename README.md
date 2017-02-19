# Kuzzle testing environment

The main purpose of this repository is to test the stability of a [kuzzle](http://kuzzle.io/) environment

Tests can be run either in a local development environment or on a continuous integration flow

<a name="how-to-run-tests-in-local-development-environment" />
## local development environment

<a name="how-to-run-tests-in-local-development-environment-configuration" />
### configuration

```bash
# kuzzle configuration
KUZZLE_REPO=kuzzleio/kuzzle
KUZZLE_VERSION=master
KUZZLE_COMMON_OBJECT_VERSION=kuzzleio/kuzzle-common-objects#master
KUZZLE_PLUGINS=kuzzleio/kuzzle-plugin-auth-passport-local#master:kuzzleio/kuzzle-plugin-logger#master

# kuzzle proxy configuration
PROXY_REPO=kuzzleio/kuzzle-proxy
PROXY_VERSION=master
PROXY_COMMON_OBJECT_VERSION=kuzzleio/kuzzle-common-objects#master
PROXY_PLUGINS=

# services configuration
ES_VERSION=5
REDIS_VERSION=3

# dependencies configuration
NODE_VERSION=6.9.5
GLOBAL_PM2_VERSION=2.0.19
GCC_VERSION=4.9

# local development environment configuration
GIT_SSL_NO_VERIFY=true
```
> **common.env** <br />
edit this file to configure your kuzzle environment, *see [environment reference](#environment-reference)*

<br />

```bash
# private configuration
GH_TOKEN=<secret token>
```
> **private.env** <br />
edit this file to configure your github token if you want to access private repositories, *this file is ignored by git*

<br />

<a name="how-to-run-tests-in-local-development-environment-run-sandbox" />
### run sandbox

```bash
# launch required services
docker-compose up -d elasticsearch redis

# then launch tests in your sandbox
docker-compose up sandbox
```
> to speed up each installation, you can persist npm cache beetween each run: <br />
- add `- "./.cache/npm:/root/.npm"` to the `services.sandbox.volumes` entry of your `docker-compose.yml` file

<br />

<a name="how-to-run-tests-in-continuous-integration-flow" />
## continuous integration flow

<a name="how-to-run-tests-in-continuous-integration-configuration" />
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
    # RC9 version
    - KUZZLE_REPO: kuzzleio/kuzzle
      KUZZLE_VERSION: 1.0.0-RC9
      PROXY_REPO: kuzzleio/kuzzle-proxy
      PROXY_VERSION: 1.0.0-RC9
    # RC9.1 version
    - KUZZLE_REPO: kuzzleio/kuzzle
      KUZZLE_VERSION: 1.0.0-RC9.1
      PROXY_REPO: kuzzleio/kuzzle-proxy
      PROXY_VERSION: 1.0.0-RC9
```
> **.travis.yml** <br />
you can add as many as configuration as you need under `env.matrix` dictionary, *see [environment reference](#environment-reference)*


<a name="how-to-run-tests-in-continuous-integration-schedule-execution" />
### schedule execution

- **master** branch is scheduled to be executed on **each week**, it's configuration should contains all stables versions

- **develop** branch is scheduled to be executed on **each day**, it's configuration should contains the main development configuration, and may contains **pre-release configurations**

<a name="environment-reference" />
## environment reference
| Variable | Default | Description |
| ---- | --- | --- |
| KUZZLE_REPO | kuzzleio/kuzzle | kuzzle github source repository |
| KUZZLE_VERSION | master | kuzzle git reference <br /><br /> *can be a branch, tag or commit version* |
| KUZZLE_COMMON_OBJECT_VERSION |  *(optional)* <br /> kuzzleio/kuzzle-common-objects#master | override kuzzle common object version <br /><br /> `<common_object_repo>#<common_object_version>` |
| KUZZLE_PLUGINS | *(optional)* <br /> kuzzleio/kuzzle-plugin-auth-passport-local#master:kuzzleio/kuzzle-plugin-logger#master | override kuzzle server plugin list <br /><br /> `<plugin_1_repo>#<plugin_1_version>:<plugin_2_repo>#<plugin_2_version>`   |
| | | |
| PROXY_REPO | kuzzleio/kuzzle-proxy | proxy github source repository |
| PROXY_VERSION | master | proxy git reference <br /><br /> *can be a branch, tag or commit version* |
| PROXY_COMMON_OBJECT_VERSION | *(optional)* <br /> kuzzleio/kuzzle-common-objects#master | override proxy common object version <br /><br /> `<common_object_repo>#<common_object_version>` |
| PROXY_PLUGINS | *(optional)* <br /> *empty* | override kuzzle proxy plugin list <br /><br /> `<plugin_1_repo>#<plugin_1_version>:<plugin_2_repo>#<plugin_2_version>`
| | | |
| ES_VERSION | 5 | define elasticsearch version <br /><br /> *can be a major, minor or patch specific version*
| REDIS_VERSION | 3 | define redis version <br /><br /> *can be a major, minor or patch specific version*
| | | |
| NODE_VERSION | 6.9.5 | define nodejs version |
| GCC_VERSION | 4.9 | define gcc version |
| GLOBAL_PM2_VERSION | *(optional)* <br /> 2.0.19 | override global pm2 version |

<a name="enhancements" />
## enhancements
- [ ] configure extra optional tests
- [ ] integrate kuzzle backoffice end-to-end tests
- [ ] multiple kuzzle server instances
- [ ] allow usage of kuzzle-load-balancer project
- [ ] link to release-request process (ci)
