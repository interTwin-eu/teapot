#!/usr/bin/env bash
set -euo pipefail

SERVER="$1"

if [[ -z "${SERVER}" ]]; then
  echo "Usage: $0 teapot-ubuntu"
  exit 1
fi

# server key
openssl genrsa -out "teapot.key" 2048

# CSR {no prompts}
openssl req -new \
  -key teapot.key \
  -subj "/CN=${SERVER}" \
  -addext "subjectAltName=DNS:${SERVER}" \
  -addext "keyUsage=digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" \
  -out "teapot.csr"

# sign with CA (no prompts)
openssl x509 -req \
  -in "teapot.csr" \
  -CA Teapot-testing.crt \
  -CAkey Teapot-testing.key \
  -CAcreateserial \
  -out "teapot.crt" \
  -days 1 \
  -sha256