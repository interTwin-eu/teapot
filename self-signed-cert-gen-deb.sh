#!/bin/bash

path=/etc/storm/webdav/
mkdir -p "${path}"

openssl req -newkey rsa:2048 -noenc -keyout "${path}"/localhost.key -x509 -days 365 -out "${path}"/localhost.crt -subj "/C=. /ST=. /L=. /O=. Corp/OU=. Dept/CN=localhost"

chmod 644 "${path}"/localhost.key

path1=/usr/local/share/ca-certificates
mkdir -p "${path1}"
cp "${path}"/localhost.crt "${path1}"/localhost.crt
chmod 644 "${path1}"/localhost.crt
update-ca-certificates

(crontab -l 2>/dev/null || true; echo "0 0 1 1 * sudo /usr/share/teapot/self-signed-cert-gen.sh") | crontab -