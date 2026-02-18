#!/bin/bash
until curl --head -fsS https://keycloak:9000/health/ready; do
  echo "Waiting for Keycloak..."
  sleep 2
done
exec gunicorn alise.daemon:app -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000