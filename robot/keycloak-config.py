from keycloak import KeycloakAdmin, KeycloakOpenID, KeycloakOpenIDConnection

# Keycloak Admin
keycloak_connection = KeycloakOpenIDConnection(
                        server_url="http://keycloak:8080/",
                        username='admin',
                        password='testing1',
                        realm_name="master",
                        verify=True)

keycloak_admin = KeycloakAdmin(connection=keycloak_connection)

# Changing Realm
keycloak_admin.create_realm(payload={"realm": "test-realm"}, skip_exists=False)
keycloak_connection.realm_name = "test-realm"

# Configuring client in the new Realm
keycloak_openid = KeycloakOpenID(server_url="http://keycloak:8080/",
                                 client_id="test-client",
                                 realm_name="test-realm",
                                 client_secret_key="test-secret")

# Keycloak admin with new realm and a new client
keycloak_connection1 = KeycloakOpenIDConnection(
                        server_url="http://keycloak:8080/",
                        username='admin',
                        password='testing1',
                        realm_name="master",
                        user_realm_name="test-realm",
                        client_id="test_client",
                        client_secret_key="test-secret",
                        verify=True)

keycloak_admin1 = KeycloakAdmin(connection=keycloak_connection1)

# Get WellKnown
config_well_known = keycloak_openid.well_known()

# Adding Users
test_user1 = keycloak_admin1.create_user({"username": "test-user1",
                                         "enabled": True,
                                         "credentials": [{"value": "secret1",
                                                          "type": "password"}]})
test_user2 = keycloak_admin1.create_user({"username": "test-user2",
                                         "enabled": True,
                                         "credentials": [{"value": "secret2",
                                                          "type": "password"}]})

# Get Code With Oauth Authorization Request
auth_url = keycloak_openid.auth_url(
    redirect_uri="http://keycloak:4242/",
    scope="email",
    state="your_state_info")

# Get Access Token With Code
access_token = keycloak_openid.token(
    grant_type='authorization_code',
    code='the_code_you_get_from_auth_url_callback',
    redirect_uri="http://keycloak:4242/")

# Get Token
token = keycloak_openid.token("user", "password")

# Get Userinfo
userinfo = keycloak_openid.userinfo(token['access_token'])