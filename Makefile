#
# Makefile for Victory
#
# Victory uses a Makefile to wrap the elixir and docker commands for
# compiling. All targets should work on both linux and MacOS, assuming
# that docker and the elixir tools are available.
#
APP_NAME ?= victory
MIX_ENV ?= dev
APP_VERSION ?= $(shell cat VERSION)
SRC_VERSION := $(shell git describe --tags --always --dirty)
VERSION ?= $(APP_VERSION)-$(SRC_VERSION)
DOCKER_REGISTRY ?= gcr.io/ox-dev-joel

echo "DOCKER_REGISTRY = $(DOCKER_REGISTRY)"

# When we use the Jenkins X registry we need to get the IP and Port from
# the k8s service environment variables.
ifeq ($(DOCKER_REGISTRY),jenkinsx)
DOCKER_REGISTRY := $(JENKINS_X_DOCKER_REGISTRY_SERVICE_HOST):$(JENKINS_X_DOCKER_REGISTRY_SERVICE_PORT)
endif

echo "DOCKER_REGISTRY = $(DOCKER_REGISTRY)"

# Configure the docker image name, making sure to prepend the registry info
# if it's in use.
#IMAGE := $(APP_NAME):$(VERSION)
IMAGE := $(APP_NAME)
ifdef DOCKER_REGISTRY
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE)
endif

echo "IMAGE = $(IMAGE)"

.PHONY: build release clean shell

# By default we compile the project. This could coneivably be changed
# to devshell.
all: build

# The deps target will be rebuilt if mix.exs or mix.lock changes.
# The target is the directory so that Make can look at the dir
# timestamp to see when it was last updated.
deps/: mix.exs mix.lock
	MIX_ENV=${MIX_ENV} mix deps.get

# Builds any files that have changed. Depends on the deps/ target
# as well as any files in lib/ and test/. This is a phony target
# since there's no way (that I know of) to examine some binary
# to determine if a rebuild is needed.
build: deps/ lib/ test/
	MIX_ENV=${MIX_ENV} mix format
	MIX_ENV=${MIX_ENV} mix compile -q

# Starts the interactive shell
interactive: build
	MIX_ENV=${MIX_ENV} iex -S mix

release: clean build
	MIX_ENV=${MIX_ENV} mix release

container: 
	sed -e "s=imageName:.*=imageName: $(IMAGE)=" skaffold.yaml > skaffold.yaml.out
	echo "Building ${IMAGE}"
	#skaffold -v debug -p gcb run -f skaffold.yaml.out -t $(VERSION)
	skaffold -v debug build -f skaffold.yaml.out -t $(VERSION)

clean:
	mix clean
	rm -rf _build/
	rm -rf deps/
	rm -rf rel/victory
