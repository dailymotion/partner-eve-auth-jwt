#!/bin/sh
set -e
mkdir -p reports
py.test -s tests \
  --junitxml=reports/report_unit_tests.xml \
  --cov eve_auth_jwt \
  --cov-config .coveragerc \
  --cov-report term \
  --cov-report xml:reports/coverage.xml \
  --cov-report html:reports
