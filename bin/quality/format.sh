#!/bin/sh
set -e
isort -rc eve_auth_jwt/.
black -l 79 eve_auth_jwt tests
