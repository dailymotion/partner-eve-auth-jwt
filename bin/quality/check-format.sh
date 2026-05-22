#!/usr/bin/env sh
set -ex

pdm run check-format "$@"
