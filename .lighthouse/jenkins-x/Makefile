# -*- mode: makefile -*-

.DEFAULT_GOAL := generate-pipelines

PKG_NAME ?= partner-eve-auth-jwt
PYTHON_VERSIONS := focal-3-9
PYTHON_BUILDER_VERSION := prod-build

JENKINS_X_DIR = $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
DM_FILES_DIR = $(realpath $(JENKINS_X_DIR)/../../.dm)

ifneq (${SKIP_DOCKER},true)
	GOMPLATE_DOCKER_IMAGE := quay.io/dailymotionadmin/gomplate-dm:3-11
	GOMPLATE := docker run \
			--rm \
			--entrypoint gomplate \
			-e PKG_NAME=${PKG_NAME} \
			-e PYTHON_BUILDER_VERSION=${PYTHON_BUILDER_VERSION} \
			-e PYTHON_VERSIONS="${PYTHON_VERSIONS}" \
			-e PYTHON_VERSION \
			-w /workspace \
			-v ${JENKINS_X_DIR}/templates:/workspace/templates \
			-v ${JENKINS_X_DIR}:/workspace/jx \
			-v ${DM_FILES_DIR}:/workspace/dm \
			${GOMPLATE_DOCKER_IMAGE}
else
	GOMPLATE := PKG_NAME=${PKG_NAME} PYTHON_VERSIONS=${PYTHON_VERSIONS} PYTHON_BUILDER_VERSION=${PYTHON_BUILDER_VERSION} gomplate
endif

.PHONY: clean-generated-files
clean-generated-files:
	@rm -f ${DM_FILES_DIR}/docker/images.yaml
	@rm -f ${JENKINS_X_DIR}/release-python-package.yaml
	@find ${JENKINS_X_DIR} -type f -name 'init-build-push-*.yaml' | xargs rm -f 2>/dev/null || true
	@find ${JENKINS_X_DIR} -type f -name 'quality-*.yaml' | xargs rm -f 2>/dev/null || true
	@rm -f ${JENKINS_X_DIR}/triggers.yaml

.PHONY: generate-unified-docker-images
generate-unified-docker-images:
	$(GOMPLATE) --verbose -f ./templates/unified-docker-images.yaml.gotmpl -o ./dm/docker/images.yaml

.PHONY: generate-init-build-push-pipeline
generate-init-build-push-pipeline:
	$(GOMPLATE) --verbose -f ./templates/init-build-push.yaml.gotmpl -o ./jx/init-build-push.yaml

.PHONY: generate-quality-pipelines
generate-quality-pipelines::
	@echo "Generate quality pipelines"
define quality-pipeline-target-generator
  generate-quality-pipelines:: ; PYTHON_VERSION=$1 $(GOMPLATE) --verbose -f ./templates/quality.yaml.gotmpl -o ./jx/quality-$1.yaml
endef
$(foreach pyv,$(PYTHON_VERSIONS),$(eval $(call quality-pipeline-target-generator,$(pyv))))

.PHONY: generate-release-pipeline
generate-release-pipeline:
	$(GOMPLATE) --verbose -f ./templates/release-python-package.yaml.gotmpl -o ./jx/release-python-package.yaml

.PHONY: generate-triggers
generate-triggers:
	$(GOMPLATE) --verbose -f ./templates/triggers.yaml.gotmpl -o ./jx/triggers.yaml

.PHONY: generate-pipelines
generate-pipelines::
ifneq ($(SKIP_DOCKER),true)
	docker pull $(GOMPLATE_DOCKER_IMAGE)
endif
generate-pipelines:: clean-generated-files generate-unified-docker-images generate-init-build-push-pipeline generate-quality-pipelines generate-release-pipeline generate-triggers
