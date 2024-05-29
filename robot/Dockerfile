FROM dvrbanec/teapot-requirements:latest

# installing Teapot
WORKDIR /tmp
COPY teapot-v*.noarch.rpm .
RUN \
    adduser teapot && \
    rpm -i teapot-v*.noarch.rpm --nodeps

WORKDIR /etc/pki/ca-trust/source/anchors
ADD https://syncandshare.desy.de/index.php/s/KY8ARPLQHzw2Fdm/download/Teapot-testing.crt .
ADD https://syncandshare.desy.de/index.php/s/37RZn84eNtDGJDX/download/testingCA.crt .
RUN update-ca-trust 

# certificates
WORKDIR /var/lib/teapot/webdav/
ADD --chown=teapot https://syncandshare.desy.de/index.php/s/GoCe4PWFJ5s95tP/download/teapot.crt .
ADD --chown=teapot https://syncandshare.desy.de/index.php/s/H9HZZWpbPFFHgx5/download/teapot.key .

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