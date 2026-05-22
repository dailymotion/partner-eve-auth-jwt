#!/usr/bin/env sh
set -ex
mkdir -p reports
pdm run test-unit "$@"
