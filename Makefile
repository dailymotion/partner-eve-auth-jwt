VERSION = $(shell git rev-parse --short HEAD)

DEVPI_USER ?= dailymotion
DEVPI_PASS ?= test1234
DEVPI_INDEX ?= https://pypi.stg.dm.gg/dailymotion/dm2
DEVPI_PKG_NAME ?= eve-auth-jwt

TO := _

ifdef BUILD_NUMBER
NUMBER = $(BUILD_NUMBER)
else
NUMBER = 1
endif

ifdef JOB_BASE_NAME
PROJECT_ENCODED_SLASH = $(subst %2F,$(TO),$(JOB_BASE_NAME))
PROJECT = $(subst /,$(TO),$(PROJECT_ENCODED_SLASH))
COMPOSE = docker compose -f docker-compose.yml -f docker-compose.ci.yml -p partner_eve_auth_jwt_$(PROJECT)_$(NUMBER)
else
COMPOSE = docker compose -p partner_eve_auth_jwt
endif

PUBLISH_CMD = ./run.sh publish $(DEVPI_INDEX) $(DEVPI_USER) $(DEVPI_PASS) $(DEVPI_PKG_NAME)
EXISTS_CMD = ./run.sh exists $(DEVPI_INDEX) $(DEVPI_USER) $(DEVPI_PASS) $(DEVPI_PKG_NAME) $(DEVPI_PKG_VERSION)

.PHONY: init
init:
	$(COMPOSE) up --no-start --no-build quality-script | true

.PHONY: quality-script
quality-script:
ifneq ($(SKIP_DOCKER),true)
	$(COMPOSE) build quality-script
	QUALITY_SCRIPT=$(QUALITY_SCRIPT) $(COMPOSE) run --rm $(EXTRA_RUN_ARGS) quality-script
else
	sh ./bin/quality/$(QUALITY_SCRIPT).sh $(EXTRA_SCRIPT_ARGS)
endif

.PHONY: format
format: EXTRA_RUN_ARGS=-v $(shell pwd):/usr/src/app
format: QUALITY_SCRIPT=format
format: quality-script

.PHONY: style
style: QUALITY_SCRIPT=style
style: quality-script

.PHONY: complexity
complexity: QUALITY_SCRIPT=complexity
complexity: quality-script

.PHONY: security-sast
security-sast: QUALITY_SCRIPT=security-sast
security-sast: quality-script

.PHONY: test-unit
test-unit: QUALITY_SCRIPT=test-unit
test-unit: quality-script

.PHONY: test
test: test-unit

.PHONY: build-clean
build-clean:
	$(COMPOSE) build build-clean
	$(COMPOSE) run --rm build-clean

.PHONY: build
build: build-clean
	$(COMPOSE) build build-package
	$(COMPOSE) run --rm build-package

.PHONY: publish
publish:
	$(COMPOSE) pull
	$(COMPOSE) run --rm --entrypoint "$(PUBLISH_CMD)" devpi

.PHONY: down
down:
	$(COMPOSE) down --volume

.PHONY: exists
exists:
	$(COMPOSE) run --rm --entrypoint "$(EXISTS_CMD)" devpi

.PHONY: tag
tag:
	git tag $(PKG_VERSION)
	git push origin $(PKG_VERSION)

.PHONY: get-version
get-version:
	@grep "_VERSION =" setup.py | egrep -o "([0-9]+\.[0-9]+\.[0-9]+)"

.PHONY: get-sandbox-version
get-sandbox-version:
	git fetch --tags
	git describe --tags

.PHONY: set-version
set-version:
	sed -i "s@_VERSION[ ]*=[ ]*['\"][0-9]\+\.[0-9]\+\.[0-9]\+['\"].@_VERSION='$(PKG_VERSION)'@" setup.py

.PHONY: prepare-sonar
prepare-sonar:
	cp sonar-project.properties.default sonar-project.properties
	echo "sonar.projectVersion=$(VERSION)" >> sonar-project.properties
