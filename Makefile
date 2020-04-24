CHART_REPO := https://nxmatic.github.io/jxlabs-nos-helmboot-resources
NAME := jxlabs-nos-helmboot-helmbootresources
OS := $(shell uname)

export HELM_HOME ?= $(shell pwd)/.helm

init:
	helm init --client-only

setup: init
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io

build: setup build-nosetup

build-nosetup: clean
	helm dependency build jxlabs-nos-helmboot-resources
	helm lint jxlabs-nos-helmboot-resources

install: clean build
	helm upgrade ${NAME} jxlabs-nos-helmboot-resources --install

upgrade: clean build
	helm upgrade ${NAME} jxlabs-nos-helmboot-resources --install

delete:
	helm delete --purge ${NAME} jxlabs-nos-helmboot-resources

clean:
	rm -rf jxlabs-nos-helmboot-resources/charts
	rm -rf jxlabs-nos-helmboot-resources/${NAME}*.tgz
	rm -rf jxlabs-nos-helmboot-resources/requirements.lock

release: clean build release-nobuild 

release-nobuild:
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" jxlabs-nos-helmboot-resources/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" jxlabs-nos-helmboot-resources/Chart.yaml
else
	exit -1
endif
	helm package --destination .cr-release-packages jxlabs-nos-helmboot-resources
#	jx step tag --version=$(VERSION)
#	jx step changelog --no-dev-release --version=$(VERSION) --batch-mode
	cr upload --config cr-config.yaml --token=$(GIT_TOKEN)
	cr index  --config cr-config.yaml --token=$(GIT_TOKEN)


test:
	cd tests && go test -v

test-regen:
	cd tests && export HELM_UNIT_REGENERATE_EXPECTED=true && go test -v
