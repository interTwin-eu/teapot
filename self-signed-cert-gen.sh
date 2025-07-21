#!/bin/bash

path=/etc/storm/webdav/
mkdir -p "${path}"

openssl req -newkey rsa:2048 -noenc -keyout "${path}"/localhost.key -x509 -days 365 -out "${path}"/localhost.crt -subj "/C=. /ST=. /L=. /O=. Corp/OU=. Dept/CN=localhost"

chmod 644 "${path}"/localhost.key

path1=/etc/pki/ca-trust/source/anchors
cp "${path}"/localhost.crt "${path1}"/localhost.crt
chmod 744 "${path1}"/localhost.crt
update-ca-trust extract

(crontab -l 2>/dev/null || true; echo "0 0 1 1 * sudo cert_generation_localhost.sh") | crontab -
