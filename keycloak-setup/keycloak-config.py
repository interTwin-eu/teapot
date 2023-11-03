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
keycloak_admin.create_realm(
    payload={"realm": "test-realm", "enabled": True}, skip_exists=False
)
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

# Get WellKnown
config_well_known = keycloak_openid.well_known()

# Adding Users
test_user1 = keycloak_admin.create_user(
    {
        "username": "test-user1",
        "enabled": True,
        "credentials": [{"value": "secret1", "type": "password"}],
    }
)
test_user2 = keycloak_admin.create_user(
    {
        "username": "test-user2",
        "enabled": True,
        "credentials": [{"value": "secret2", "type": "password"}],
    }
)
