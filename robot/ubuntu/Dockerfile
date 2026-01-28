# trunk-ignore-all(checkov/CKV_DOCKER_2)
# trunk-ignore-all(checkov/CKV_DOCKER_3)
# trunk-ignore-all(trivy/DS002)
# trunk-ignore-all(trivy/DS026)
# trunk-ignore-all(hadolint/DL3007)
# hadolint ignore=DL3008
FROM ubuntu:24.04

WORKDIR /tmp
COPY teapot_*-1_all.deb .
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        ca-certificates \
        sudo \
        vim \
        /tmp/teapot_*-1_all.deb && \
    /usr/share/teapot/self-signed-cert-gen.sh && \
    rm -rf /var/lib/apt/lists/*


WORKDIR /usr/local/share/ca-certificates
ADD --chmod=644 https://letsencrypt.org/certs/isrgrootx1.pem .
ADD --chmod=644 https://letsencrypt.org/certs/lets-encrypt-r3.pem .
ADD --chmod=644 http://crl.usertrust.com/USERTrustRSACertificationAuthority.crl .
ADD --chmod=644 http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt .
ADD --chmod=644 https://syncandshare.desy.de/index.php/s/KY8ARPLQHzw2Fdm/download/Teapot-testing.crt .
ADD --chmod=644 https://syncandshare.desy.de/index.php/s/AT4LMp9qJ3yxs9x/download/teapot.crt .
RUN update-ca-certificates

WORKDIR /var/lib/teapot/webdav/
ADD --chown=teapot --chmod=644 https://syncandshare.desy.de/index.php/s/KY8ARPLQHzw2Fdm/download/Teapot-testing.crt .
ADD --chown=teapot --chmod=644 https://syncandshare.desy.de/index.php/s/AT4LMp9qJ3yxs9x/download/teapot.crt .
ADD --chown=teapot --chmod=644 https://syncandshare.desy.de/index.php/s/zY6agLE29TAtkke/download/teapot.key .

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