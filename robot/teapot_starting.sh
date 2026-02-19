#!/bin/bash
until curl --head -fsS https://keycloak:9000/health/ready; do
  echo "Waiting for Keycloak..."
  sleep 2
done

eval `oidc-agent`
echo "" > pw-file
oidc-gen --flow password -f /tmp/test_client_config_final.json --op-username test-user1 --op-password secret1  --prompt none --pw-file pw-file test-user1
rm pw-file

response=$(curl -H "Authorization: Bearer $(oidc-token test-user1)" http://alise:8000/api/v1/target/keycloak_test/get_apikey)
apikey=$(echo "$response" | jq -r '.apikey')
sed -i "s/^APIKEY =.*/APIKEY = $apikey/" /etc/teapot/config.ini

exec python3 teapot.py