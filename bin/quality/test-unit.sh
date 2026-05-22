#!/bin/sh
set -e
REPORT_DIR="${REPORT_DIR:-/tmp/reports}"
mkdir -p "${REPORT_DIR}"
py.test -s tests \
  --junitxml="${REPORT_DIR}/report_unit_tests.xml" \
  --cov eve_auth_jwt \
  --cov-config .coveragerc \
  --cov-report term \
  --cov-report "xml:${REPORT_DIR}/coverage.xml"
