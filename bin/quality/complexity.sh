#!/bin/sh
set -e
xenon --ignore "tests" --max-absolute C --max-modules C --max-average C .
