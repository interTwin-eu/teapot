#!/usr/bin/env bash
set -euo pipefail

SERVER="$1"

if [[ -z "${SERVER}" ]]; then
  echo "Usage: $0 <server-name>"
  exit 1
fi

CA_CERT="Teapot-testing.crt"
CA_KEY="Teapot-testing.key"


if [[ ! -f "${CA_CERT}" || ! -f "${CA_KEY}" ]]; then
    echo "CA certificate or key not found in current directory"
    exit 1
fi

# server key
openssl genrsa -out "teapot.key" 2048

# CSR
openssl req -new \
  -key teapot.key \
  -subj "/CN=${SERVER}" \
  -addext "subjectAltName=DNS:${SERVER}" \
  -addext "keyUsage=digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" \
  -out "teapot.csr"

# ext file to include SAN when signing
cat > teapot.ext.cnf <<EOF
[ v3_req ]
subjectAltName = DNS:${SERVER}
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
EOF

# sign with CA (no prompts)
openssl x509 -req \
  -in "teapot.csr" \
  -CA Teapot-testing.crt \
  -CAkey Teapot-testing.key \
  -CAcreateserial \
  -out "teapot.crt" \
  -days 1 \
  -sha256 \
  -extfile teapot.ext.cnf \
  -extensions v3_req