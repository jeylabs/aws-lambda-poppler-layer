#!/bin/bash

set -e
set -u
set -x

cd /opt

ls -la

zip -q -r /export/${ZIP_FILE_NAME}.zip . -x *include* *share*