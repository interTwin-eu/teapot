from keycloak import KeycloakAdmin, KeycloakOpenID, KeycloakOpenIDConnection

# Keycloak Admin
keycloak_connection = KeycloakOpenIDConnection(
    server_url="http://keycloak:8080/",
    username="admin",
    password="testing1",
    realm_name="master",
    verify=True,
)

keycloak_admin = KeycloakAdmin(connection=keycloak_connection)

# Changing Realm
keycloak_connection.realm_name = "test-realm"

# Create a client
client = keycloak_admin.create_client(
    payload={
        "name": "test-client",
        "clientId": "test-client",
        "secret": "test-secret",
        "redirectUris": ["http://localhost:4242/"],
        "enabled": True,
        "directAccessGrantsEnabled": True,
    }
)

# Configuring client in the new Realm
keycloak_openid = KeycloakOpenID(
    server_url="http://keycloak:8080/",
    client_id="test-client",
    realm_name="test-realm",
    client_secret_key="test-secret",
)
