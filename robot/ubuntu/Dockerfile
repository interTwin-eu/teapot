# trunk-ignore-all(checkov/CKV_DOCKER_2)
# trunk-ignore-all(checkov/CKV_DOCKER_3)
# trunk-ignore-all(trivy/DS002)
# trunk-ignore-all(trivy/DS026)
# trunk-ignore-all(hadolint/DL3007)
FROM ubuntu:24.04

WORKDIR /tmp
COPY teapot_*-1_all.deb .
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        ca-certificates \
        sudo \
        vim \
        /tmp/teapot_*-1_all.deb && \
    /usr/share/teapot/self-signed-cert-gen.sh && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=644 Teapot-testing.crt /usr/local/share/ca-certificates
COPY --chmod=644 Teapot-testing.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.key /var/lib/teapot/webdav/
RUN update-ca-certificates

WORKDIR /etc/teapot
COPY --chmod=644 user-mapping.csv .
RUN \
    adduser test-user1 && \
    adduser test-user2  && \
    su -c "mkdir -p /home/test-user1/interTwin" test-user1 && \
    su -c "mkdir -p /home/test-user1/interTwin_extra" test-user1 && \
    su -c "mkdir -p /home/test-user2/interTwin" test-user2 && \
    su -c "mkdir -p /home/test-user2/interTwin_extra" test-user2

EXPOSE 8081

WORKDIR /usr/share/teapot/
USER teapot
CMD ["python3", "teapot.py"]