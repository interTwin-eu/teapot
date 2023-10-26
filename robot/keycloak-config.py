from keycloak import KeycloakAdmin, KeycloakOpenID, KeycloakOpenIDConnection

# Configure client
keycloak_openid = KeycloakOpenID(server_url="http://localhost:8080/auth/",
                                 client_id="test_client",
                                 realm_name="test_realm",
                                 client_secret_key="secret-key")
# Get WellKnown
config_well_known = keycloak_openid.well_known()

# Get Code With Oauth Authorization Request
auth_url = keycloak_openid.auth_url(
    redirect_uri="http://localhost:4242")

# Get Access Token With Code
access_token = keycloak_openid.token(
    grant_type='authorization_code',
    code='the_code_you_get_from_auth_url_callback',
    redirect_uri="http://localhost:4242")

# Get Token
token = keycloak_openid.token("user", "password")

# Get Userinfo
userinfo = keycloak_openid.userinfo(token['access_token'])

keycloak_connection = KeycloakOpenIDConnection(
                        server_url="http://localhost:8080/",
                        username='admin',
                        password='testing1',
                        realm_name="test_realm",
                        user_realm_name="test_realm",
                        client_id="test_client",
                        client_secret_key="secret-key",
                        verify=True)

keycloak_admin = KeycloakAdmin(connection=keycloak_connection)

test_user1 = keycloak_admin.create_user({"username": "test_user1", "enabled": True, "credentials": [{"value": "secret1","type": "password"}]})
test_user2 = keycloak_admin.create_user({"username": "test_user2", "enabled": True, "credentials": [{"value": "secret2","type": "password"}]})
