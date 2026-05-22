VERSION = $(shell git rev-parse --short HEAD)
TO := _

ifdef BUILD_NUMBER
NUMBER = $(BUILD_NUMBER)
else
NUMBER = 1
endif

COMPOSE_CMD = $(shell \
	if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then \
		echo "docker compose"; \
	else \
		echo "docker-compose"; \
	fi \
)

COMPOSE = $(COMPOSE_CMD) \
	-f ./.docker/docker-compose.yml \
	-f ./.docker/docker-compose.dev.yml \
	-p partner_eve_auth_jwt

ifdef JOB_BASE_NAME
PROJECT_ENCODED_SLASH = $(subst %2F,$(TO),$(JOB_BASE_NAME))
PROJECT = $(subst /,$(TO),$(PROJECT_ENCODED_SLASH))
COMPOSE := $(COMPOSE_CMD) \
	-f ./.docker/docker-compose.yml \
	-f ./.docker/docker-compose.dev.yml \
	-f docker-compose.ci.yml \
	-p partner_eve_auth_jwt_$(PROJECT)_$(NUMBER)
endif

BUILD = COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 $(COMPOSE) build
RUN = $(COMPOSE) run $(EXTRA_RUN_ARGS) --rm

DEVPI_USER ?= dailymotion
DEVPI_PASS ?= test1234
DEVPI_INDEX ?= https://pypi.stg.dm.gg/dailymotion/dm2
DEVPI_PKG_NAME ?= eve-auth-jwt

PUBLISH_CMD = ./run.sh publish $(DEVPI_INDEX) $(DEVPI_USER) $(DEVPI_PASS) $(DEVPI_PKG_NAME)
EXISTS_CMD = ./run.sh exists $(DEVPI_INDEX) $(DEVPI_USER) $(DEVPI_PASS) $(DEVPI_PKG_NAME) $(DEVPI_PKG_VERSION)

.PHONY: init
init:
	$(COMPOSE) up --no-start --no-build quality-script | true

.PHONY: quality-script
quality-script:
ifneq ($(SKIP_DOCKER),true)
	$(BUILD) quality-script
	QUALITY_SCRIPT=$(QUALITY_SCRIPT) $(RUN) quality-script
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

.PHONY: build
build:
	$(BUILD) build-package
	$(RUN) build-package

.PHONY: publish
publish:
	$(COMPOSE) run --rm --entrypoint "$(PUBLISH_CMD)" devpi

.PHONY: down
down:
	$(COMPOSE) down --volume

.PHONY: get-version
get-version:
	@grep '^version = ' pyproject.toml | sed 's/.*"\(.*\)".*/\1/'

.PHONY: get-sandbox-version
get-sandbox-version:
	git fetch --tags
	git describe --tags

.PHONY: set-version
set-version:
	sed -i 's/^version = .*/version = "$(PKG_VERSION)"/' pyproject.toml
