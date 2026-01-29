#!/usr/bin/env bash
set -euo pipefail

SERVER="$1"

if [[ -z "${SERVER}" ]]; then
  echo "Usage: $0 teapot-ubuntu"
  exit 1
fi

# server key
openssl genrsa -out "${SERVER}.key" 2048

# CSR {no prompts}
openssl req -new \
  -key "${SERVER}.key" \
  -subj "/CN=${SERVER}" \
  -addext "subjectAltName=DNS:${SERVER}" \
  -addext "keyUsage=digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth" \
  -out "${SERVER}.csr"

# sign with CA (no prompts)
openssl x509 -req \
  -in "${SERVER}.csr" \
  -CA Teapot-testing.crt \
  -CAkey Teapot-testing.key \
  -CAcreateserial \
  -out "${SERVER}.crt" \
  -days 1 \
  -sha256