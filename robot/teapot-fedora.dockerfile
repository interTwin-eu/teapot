# trunk-ignore-all(trivy/DS026)
FROM fedora:39

# installing Teapot
COPY teapot-*.x86_64.rpm /tmp
# hadolint ignore=DL3041
RUN dnf install -y curl && \
    dnf install -y cronie oidc-agent jq sed /tmp/teapot-*.x86_64.rpm && \
    /usr/share/teapot/self-signed-cert-gen.sh && \
    dnf clean all

# certificates
COPY --chmod=644 Teapot-testing.crt /etc/pki/ca-trust/source/anchors
COPY --chmod=644 Teapot-testing.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.key /var/lib/teapot/webdav/
RUN update-ca-trust

# configuring teapot for testing 
COPY --chmod=744 testing-configurations/user-mapping.csv /etc/teapot
COPY --chmod=644 test_client_config_final.json /tmp
COPY --chmod=744 teapot_starting.sh /usr/share/teapot/

RUN \
    adduser test-user1 && \
    adduser test-user2 && \
    usermod -a -G teapot test-user1 && \
    usermod -a -G teapot test-user2 && \
    su -c "mkdir -p /home/test-user1/interTwin" test-user1 && \
    su -c "mkdir -p /home/test-user1/interTwin_extra" test-user1 && \
    su -c "mkdir -p /home/test-user2/interTwin" test-user2 && \
    su -c "mkdir -p /home/test-user2/interTwin_extra" test-user2

EXPOSE 8081

WORKDIR /usr/share/teapot/
USER teapot
CMD ["./teapot_starting.sh"]
