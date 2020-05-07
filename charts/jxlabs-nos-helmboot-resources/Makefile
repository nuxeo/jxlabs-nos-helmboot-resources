CHART_REPO := gs://jxlabs-nos-charts
NAME := jxlabs-nos-helmboot-resources

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

clean:
	rm -rf charts
	rm -rf ${NAME}*.tgz

release: clean
	sed -i -e "s/version:.*/version: $(VERSION)/" Chart.yaml
	helm dependency build
	helm lint
	helm package .
	helm gcs push ${NAME}*.tgz $(CHART_REPO)
	rm -rf ${NAME}*.tgz%
