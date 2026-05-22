# syntax = docker/dockerfile:1
ARG PYTHON_VERSION=focal-3-9
ARG BASE_IMAGE=quay.io/dailymotionadmin/python-dm

# ### #
# PDM #
# ### #
# hadolint ignore=DL3006
FROM $BASE_IMAGE:$PYTHON_VERSION AS pdm

ENV VIRTUAL_ENV="/opt/.venv"

USER root

RUN mkdir -p /opt/.venv /opt/.venv.pdm /usr/src/app /app/.cache/pip /app/.cache/pdm && \
        chown -R dm:dm /opt/.venv /opt/.venv.pdm /usr/src/app /app/.cache

USER dm

ENV PATH="/opt/.venv.pdm/bin:$PATH"

RUN python -m venv /opt/.venv /opt/.venv.pdm

RUN --mount=type=cache,uid=1000,gid=1000,mode=0755,id=pip,target=/app/.cache/pip \
        pip install --no-cache-dir pdm==2.16.1 pdm-version==2.0.0

WORKDIR /usr/src/app

# ####### #
# Builder #
# ####### #
FROM pdm AS builder

COPY --chown=dm pyproject.toml README.rst ./

RUN mkdir -p eve_auth_jwt && touch eve_auth_jwt/__init__.py

RUN --mount=type=cache,uid=1000,gid=1000,mode=0755,id=pdm,target=/app/.cache/pdm \
        pdm lock -G :all && \
        pdm install --no-editable --no-self --prod

# ########## #
# Prod build #
# ########## #
FROM builder AS prod-build

COPY --chown=dm eve_auth_jwt eve_auth_jwt
COPY --chown=dm tests tests

RUN --mount=type=cache,uid=1000,gid=1000,mode=0755,id=pdm,target=/app/.cache/pdm \
        pdm sync -G :all --prod

# ### #
# Dev #
# ### #
FROM builder AS dev

ENV PATH="/opt/.venv/bin:$PATH"

COPY --from=builder --chown=dm /opt/.venv /opt/.venv

RUN --mount=type=cache,uid=1000,gid=1000,mode=0755,id=pdm,target=/app/.cache/pdm \
        pdm sync -G :all --dev

COPY --chown=dm . .
