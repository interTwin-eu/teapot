FROM dvrbanec/teapot-requirements:latest

# installing Teapot
WORKDIR /tmp
COPY teapot-v*.noarch.rpm .
RUN \
    adduser teapot && \
    rpm -i teapot-v*.noarch.rpm --nodeps

WORKDIR /etc/pki/ca-trust/source/anchors
COPY testing-configurations/Teapot-testing.crt .
RUN update-ca-trust 

# certificates
WORKDIR /var/lib/teapot/webdav/
COPY --chown=teapot testing-configurations/teapot.crt .
COPY --chown=teapot testing-configurations/teapot.key .

# configuring teapot for testing
WORKDIR /etc/teapot
ADD testing-configurations/storage-areas .
ADD testing-configurations/user-mapping.csv .
RUN \
    chmod +r storage-areas && \
    chmod +r user-mapping.csv && \
    adduser test-user1 && \
    adduser test-user2  && \
    su -c "mkdir -p /home/test-user1/interTwin" test-user1 && \
    su -c "mkdir -p /home/test-user1/interTwin_extra" test-user1 && \
    su -c "mkdir -p /home/test-user2/interTwin" test-user2 && \
    su -c "mkdir -p /home/test-user2/interTwin_extra" test-user2

EXPOSE 8081

WORKDIR /usr/share/teapot/

CMD su -c ./run-teapot.sh teapot