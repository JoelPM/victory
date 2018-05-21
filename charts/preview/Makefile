OS := $(shell uname)


DOCKER_REGISTRY ?= gcr.io/ox-dev-joel

# When we use the Jenkins X registry we need to get the IP and Port from
# the k8s service environment variables.
ifeq ($(DOCKER_REGISTRY),jenkinsx)
DOCKER_REGISTRY := $(JENKINS_X_DOCKER_REGISTRY_SERVICE_HOST):$(JENKINS_X_DOCKER_REGISTRY_SERVICE_PORT)
endif

preview:
	helm init --client-only
	helm repo add chartmuseum http://jenkins-x-chartmuseum:8080
	helm repo add chartmuseum https://chartmuseum.build.cd.jenkins-x.io
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(PREVIEW_VERSION)/" Chart.yaml
	sed -i "" -e "s/version:.*/version: $(PREVIEW_VERSION)/" ../*/Chart.yaml
	sed -i "" -e "s/tag: .*/tag: $(PREVIEW_VERSION)/" values.yaml
else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(PREVIEW_VERSION)/" Chart.yaml
	sed -i -e "s/version:.*/version: $(PREVIEW_VERSION)/" ../*/Chart.yaml
	sed -i -e "s/repository: .*/repository: $(DOCKER_REGISTRY)\/$(ORG)\/$(APP_NAME)/" values.yaml
	sed -i -e "s/tag: .*/tag: $(PREVIEW_VERSION)/" values.yaml
else
	echo "platfrom $(OS) not supported to release from"
	exit -1
endif
	echo "  version: $(PREVIEW_VERSION)" >> requirements.yaml
	helm dependency build
	helm lint
