user1=test-user1
curl -s -H "Authorization: Bearer $(oidc-token test-user1)" http://keycloak:8080/realms/test-realm/protocol/openid-connect/userinfo | jq . | grep sub | while read column sub; do \
    sub1=`sed -e 's/^"//' -e 's/",$//' <<< $sub` \
    && echo -e "$user1 $sub1\n" >> /etc/teapot/user-mapping.csv\
    ;done

user2=test-user2
curl -s -H "Authorization: Bearer $(oidc-token test-user2)" http://keycloak:8080/realms/test-realm/protocol/openid-connect/userinfo | jq . | grep sub | while read column sub; do \
    sub2=`sed -e 's/^"//' -e 's/",$//' <<< $sub` \
    && echo -e "$user2 $sub2\n" >> /etc/teapot/user-mapping.csv\
    ;done