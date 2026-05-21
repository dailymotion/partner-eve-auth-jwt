#!/bin/sh
set -e
bandit -r ./eve_auth_jwt ./tests
