#
# Makefile for Victory
#
# Victory uses a Makefile to wrap the elixir and docker commands for
# compiling. All targets should work on both linux and MacOS, assuming
# that docker and the elixir tools are available.
#
APP_NAME ?= victory
APP_PORT ?= 4000
MIX_ENV ?= dev
ELIXIR_VERSION ?= 1.6.4-alpine
APP_VERSION ?= $(shell cat VERSION)
SRC_VERSION := $(shell git describe --tags --always --dirty)
CONTAINER=$(APP_NAME):$(APP_VERSION)-$(SRC_VERSION)

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

container: clean
	docker build --build-arg APP_NAME=$(APP_NAME) -t $(CONTAINER) .

container.run: 
	docker run --rm -p $(APP_PORT):4000 $(CONTAINER)

clean:
	mix clean
	rm -rf _build/
	rm -rf deps/
	rm -rf rel/victory
