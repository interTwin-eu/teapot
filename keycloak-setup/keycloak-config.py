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
