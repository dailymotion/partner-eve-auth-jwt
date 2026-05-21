# syntax = docker/dockerfile:1
ARG PYTHON_VERSION=focal-3-8
ARG BASE_IMAGE=quay.io/dailymotionadmin/python-dm:${PYTHON_VERSION}

FROM ${BASE_IMAGE} AS ci

USER root
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install --no-install-recommends -y gcc && \
    apt-get -y purge --auto-remove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

USER dm
WORKDIR /usr/src/app
ENV PATH="/app/.local/bin:${PATH}"

COPY --chown=dm requirements*.txt /usr/src/app/
RUN pip install -i https://pypi.dm.gg/dm/prod --no-cache-dir -r requirements-dev.txt -r requirements.txt

COPY --chown=dm . /usr/src/app

FROM ci AS prod-build
RUN python setup.py sdist
