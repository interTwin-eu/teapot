# trunk-ignore-all(trivy/DS026)
FROM ubuntu:24.04

WORKDIR /tmp
COPY teapot_*-1_all.deb .
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        sudo \
        ca-certificates \
        oidc-agent \
        curl \
        jq \
        sed \
        /tmp/teapot_*-1_all.deb && \
    /usr/share/teapot/self-signed-cert-gen.sh && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=644 Teapot-testing.crt /usr/local/share/ca-certificates
COPY --chmod=644 Teapot-testing.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.crt /var/lib/teapot/webdav/
COPY --chown=teapot --chmod=644  teapot.key /var/lib/teapot/webdav/
RUN update-ca-certificates

COPY --chmod=644 testing-configurations/user-mapping.csv /etc/teapot
COPY --chmod=644 test_client_config_final.json /tmp
COPY --chmod=744 teapot_starting.sh /usr/share/teapot/

RUN \
    adduser test-user1 && \
    adduser test-user2 && \
    install -d -o test-user1 -g test-user1 -m 700 /home/test-user1/interTwin && \
    install -d -o test-user2 -g test-user2 -m 700 /home/test-user2/interTwin && \
    install -d -o teapot -g teapot -m 755 /data/ && \
    install -d -o test-user1 -g test-user1 -m 700 /data/test-user1 && \
    install -d -o test-user2 -g test-user2 -m 700 /data/test-user2

EXPOSE 8081

WORKDIR /usr/share/teapot/
USER teapot
CMD ["./teapot_starting.sh"]