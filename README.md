# Kuzzle testing environment

### environment configuration

```
KUZZLE_REPO=kuzzleio/kuzzle
KUZZLE_VERSION=master
KUZZLE_KEEP_DEFAULT_PLUGIN=true
KUZZLE_COMMON_OBJECT_VERSION=kuzzleio/kuzzle-common-objects#master

PROXY_REPO=kuzzleio/kuzzle-proxy
PROXY_VERSION=master
PROXY_KEEP_DEFAULT_PLUGIN=true
PROXY_COMMON_OBJECT_VERSION=kuzzleio/kuzzle-common-objects#master
```
> edit **common.env** files
> kuzzle/proxy/common-objects version can be a branch, tag or commit reference


### run tests

```bash
# launch required services
docker-compose up -d elasticsearch redis

# then launch tests in your sandbox
docker-compose up sandbox
```
> all components is reinstalled on each run, but npm cache is persisted though docker volumes
> you may clear it, to do so, empty the **.cache/npm** folder


### todo
- [ ] custom plugin
- [ ] backoffice 
