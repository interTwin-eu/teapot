# trunk-ignore-all(checkov/CKV_DOCKER_2)
# trunk-ignore-all(checkov/CKV_DOCKER_3)
# trunk-ignore-all(trivy/DS002)
# trunk-ignore-all(trivy/DS026)
# trunk-ignore-all(hadolint/DL3007)
FROM dvrbanec/teapot-requirements:3.0

# installing Teapot
WORKDIR /tmp
COPY teapot-*.x86_64.rpm .
RUN \
    adduser teapot && \
    rpm -i teapot-*.x86_64.rpm

# certificates
COPY --chmod=644 Teapot-testing.crt /etc/pki/ca-trust/source/anchors
COPY --chmod=644 Teapot-testing.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.key /var/lib/teapot/webdav/
RUN update-ca-trust

# configuring teapot for testing
WORKDIR /etc/teapot
COPY --chmod=744 testing-configurations/user-mapping.csv .
RUN \
    adduser test-user1 && \
    adduser test-user2 && \
    usermod -a -G teapot test-user1 && \
    usermod -a -G teapot test-user2 && \
    su -c "mkdir -p /home/test-user1/interTwin" test-user1 && \
    su -c "mkdir -p /home/test-user1/interTwin_extra" test-user1 && \
    su -c "mkdir -p /home/test-user2/interTwin" test-user2 && \
    su -c "mkdir -p /home/test-user2/interTwin_extra" test-user2

RUN    /usr/share/teapot/self-signed-cert-gen.sh

EXPOSE 8081

WORKDIR /usr/share/teapot/
USER teapot
CMD ["python3", "teapot.py"]
