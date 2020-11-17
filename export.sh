#!/bin/bash

set -Eeuxo pipefail

cd /opt
cp -R /runtime/* /opt/

ls -la

sed -i '/<!-- Font directory list -->/a <dir>/tmp/fonts</dir>' /opt/etc/fonts/fonts.conf
sed -i '/<!-- Font directory list -->/a <dir>/opt/share/fonts</dir>' /opt/etc/fonts/fonts.conf

zip --quiet --recurse-paths --symlinks "/export/${ZIP_FILE_NAME}.zip" .
