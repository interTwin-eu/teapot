#!/bin/bash

path=/var/lib/teapot/webdav
mkdir -p "$path"

openssl req -newkey rsa:2048 -keyout "$path"/lolcahost.key -x509 -days 365 -out "$path"/localhost.crt -subj "/C=. /ST=. /L=. /O=. Corp/OU=. Dept/CN=localhost"

chmod ugo+r "$path"/localhost.key

path1=/etc/pki/ca-trust/source/anchors
cp "$path"/localhost.crt "$path1"/localhost.crt
update-ca-trust

crontab -l | { cat; echo "0 0 1 1 * sudo cert_generation_localhost.sh"; } | crontab -
