#!/bin/bash

set -e
set -u
set -x

cd /opt

ls -la

zip --quiet --recurse-paths /export/${ZIP_FILE_NAME}.zip . --exclude "*include*" "*share*"