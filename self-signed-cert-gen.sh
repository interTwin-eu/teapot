#!/bin/bash

path=/var/lib/teapot/webdav
mkdir -p "$path"

openssl req -nodes -x509 -sha256 -newkey rsa:4096 \
  -keyout "$path"/localhost.key \
  -out "$path"/localhost.crt \
  -days 356 \
  -subj "/C=. /ST=. /L=. /O=. Corp/OU=. Dept/CN=localhost"  \
  -addext "subjectAltName = DNS:localhost,DNS:localhost"

chmod ugo+r "$path"/localhost.key

path1=/etc/pki/ca-trust/source/anchors
cp "$path"/localhost.crt "$path1"/localhost.crt
update-ca-trust

crontab -l | { cat; echo "0 0 1 1 * sudo cert_generation_localhost.sh"; } | crontab -
