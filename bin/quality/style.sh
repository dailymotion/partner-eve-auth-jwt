#!/bin/sh
set -e
isort --check-only -rc eve_auth_jwt/.
black -l 79 --check eve_auth_jwt tests
pylint --reports=n eve_auth_jwt || test $? -le 32
