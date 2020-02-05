#!/bin/bash

set -e
set -u
set -x

cd /opt
cp /runtime/* /opt/

ls -la

sed -i '/<!-- Font directory list -->/a <dir>/opt/share/fonts</dir>' /opt/etc/fonts/fonts.conf

zip --quiet --recurse-paths /export/${ZIP_FILE_NAME}.zip .
