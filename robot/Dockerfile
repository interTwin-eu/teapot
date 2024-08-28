# trunk-ignore-all(checkov/CKV_DOCKER_2)
# trunk-ignore-all(checkov/CKV_DOCKER_3)
# trunk-ignore-all(trivy/DS002)
# trunk-ignore-all(trivy/DS026)
# trunk-ignore-all(hadolint/DL3007)
FROM dvrbanec/teapot-requirements:1.5

# installing Teapot
WORKDIR /tmp
COPY teapot-v*.x86_64.rpm .
RUN \
    adduser teapot && \
    rpm -i teapot-v*.x86_64.rpm

WORKDIR /etc/pki/ca-trust/source/anchors
ADD --chmod=744 https://syncandshare.desy.de/index.php/s/KY8ARPLQHzw2Fdm/download/Teapot-testing.crt .
ADD --chmod=744 https://syncandshare.desy.de/index.php/s/TfosBEAmNnMRQtL/download/localhost.crt .
RUN update-ca-trust 

# certificates
WORKDIR /var/lib/teapot/webdav/
ADD --chown=teapot --chmod=644 https://syncandshare.desy.de/index.php/s/AT4LMp9qJ3yxs9x/download/teapot.crt .
ADD --chown=teapot --chmod=644 https://syncandshare.desy.de/index.php/s/zY6agLE29TAtkke/download/teapot.key .
ADD --chown=teapot --chmod=644 https://syncandshare.desy.de/index.php/s/TfosBEAmNnMRQtL/download/localhost.crt .
ADD --chown=teapot --chmod=644 https://syncandshare.desy.de/index.php/s/Z4xFNWMCCq4KRFm/download/localhost.key .

# configuring teapot for testing
WORKDIR /etc/teapot
COPY --chmod=744 testing-configurations/storage-areas .
COPY --chmod=744 testing-configurations/user-mapping.csv .
RUN \
    adduser test-user1 && \
    adduser test-user2  && \
    su -c "mkdir -p /home/test-user1/interTwin" test-user1 && \
    su -c "mkdir -p /home/test-user1/interTwin_extra" test-user1 && \
    su -c "mkdir -p /home/test-user2/interTwin" test-user2 && \
    su -c "mkdir -p /home/test-user2/interTwin_extra" test-user2

EXPOSE 8081

WORKDIR /usr/share/teapot/

CMD su -c "python3 teapot.py" teapot