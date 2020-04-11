CHART_REPO := https://nxmatic.github.io/jxlabs-nos-resources
NAME := jxlabs-nos-resources
OS := $(shell uname)

export HELM_HOME ?= $(shell pwd)/.helm

init:
	helm init --client-only

setup: init
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io

build: setup build-nosetup

build-nosetup: clean
	helm dependency build jxlabs-nos-resources
	helm lint jxlabs-nos-resources

install: clean build
	helm upgrade ${NAME} jxlabs-nos-resources --install

upgrade: clean build
	helm upgrade ${NAME} jxlabs-nos-resources --install

delete:
	helm delete --purge ${NAME} jxlabs-nos-resources

clean:
	rm -rf jxlabs-nos-resources/charts
	rm -rf jxlabs-nos-resources/${NAME}*.tgz
	rm -rf jxlabs-nos-resources/requirements.lock

release: clean build .cr-release-packages
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" jxlabs-nos-resources/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" jxlabs-nos-resources/Chart.yaml
else
	exit -1
endif
	helm package --destination .cr-release-packages jxlabs-nos-resources
	jx step tag --version=$(VERSION)
	jx step changelog --version=v$(VERSION) --batch-mode
	cr upload --config cr-config.yaml --token=$(GIT_TOKEN)
	cr index  --config cr-config.yaml --token=$(GIT_TOKEN)


test:
	cd tests && go test -v

test-regen:
	cd tests && export HELM_UNIT_REGENERATE_EXPECTED=true && go test -v
