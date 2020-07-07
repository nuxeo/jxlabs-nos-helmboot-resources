NAME := jxlabs-nos-helmboot-resources

helm-version := $(shell helm version --client --template '{{.Client.SemVer}}' 2>/dev/null || helm version --client --template '{{.Version}}' 2>/dev/null)

setup:
ifeq ($(filter v3%,$(helm-version)),)
	helm init --client-only
	test ! -f $(HOME)/.helm/plugins/helm-gcs && helm plugin install https://github.com/hayorov/helm-gcs --version v0.2.2
else
	test ! -f $(HOME)/.local/share/helm/plugins/helm-gcs && helm plugin install https://github.com/hayorov/helm-gcs --version v0.3.1
endif
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io
	helm repo add jxlabs-nos gs://jxlabs-nos-charts

build: clean
	rm -rf Chart.lock
	helm dependency build
	helm lint

install: clean build
	helm install . --name ${NAME}

upgrade: clean build
	helm upgrade ${NAME} .

delete:
	helm delete --purge ${NAME}

clean: setup
	rm -rf charts
	rm -rf ${NAME}*.tgz

release: clean
	sed -i -e "s/version:.*/version: $(VERSION)/" Chart.yaml
	helm dependency build
	helm lint
	helm package .
	helm gcs push --force ${NAME}-${VERSION}.tgz jxlabs-nos

