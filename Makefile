CHART_REPO := https://nxmatic.github.io/jxlabs-nos-helmboot-resources
NAME := jxlabs-nos-helmboot-helmbootresources
OS := $(shell uname)

HELM_HOME ?= $(shell pwd)/.helm

export

init:
	helm init --client-only

setup: init
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io

build: setup build-nosetup

build-nosetup: clean
	cd charts && helm dependency build jxlabs-nos-helmboot-resources
	cd charts && helm lint jxlabs-nos-helmboot-resources

install: clean build
	cd charts && helm upgrade ${NAME} jxlabs-nos-helmboot-resources --install

upgrade: clean build
	cd charts && helm upgrade ${NAME} jxlabs-nos-helmboot-resources --install

delete:
	cd charts && helm delete --purge ${NAME} jxlabs-nos-helmboot-resources

clean:
	rm -fr .bin .cr-*
#	rm -rf jxlabs-nos-helmboot-resources/charts
#	rm -rf jxlabs-nos-helmboot-resources/${NAME}*.tgz
#	rm -rf jxlabs-nos-helmboot-resources/requirements.lock

release: clean build release-nobuild 

.bin/cr: | .bin
	[ -x /usr/local/bin/cr ] && ln -s /usr/local/bin/cr .bin/cr || (curl -L -s https://github.com/helm/chart-releaser/releases/download/v0.2.3/chart-releaser_0.2.3_linux_amd64.tar.gz | tar xvCfz .bin -)

.bin .cr-release-packages .cr-index:
	mkdir $@


release-nobuild: GIT_TOKEN := $(shell jx step credential --name=jx-pipeline-git-github-github --key=password)
release-nobuild: | .bin/cr .cr-release-packages .cr-index
release-nobuild:
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" charts/jxlabs-nos-helmboot-resources/Chart.yaml
else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" charts/jxlabs-nos-helmboot-resources/Chart.yaml
else
	exit -1
endif
	cd charts && helm package --destination ../.cr-release-packages jxlabs-nos-helmboot-resources
	.bin/cr upload --config cr-config.yaml --token=$${GIT_TOKEN}
	.bin/cr index  --config cr-config.yaml --token=$${GIT_TOKEN}

test:
	cd tests && go test -v

test-regen:
	cd tests && export HELM_UNIT_REGENERATE_EXPECTED=true && go test -v
