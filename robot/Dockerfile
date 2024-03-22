FROM dvrbanec/teapot-requirements

# installing teapot
WORKDIR /tmp
COPY /home/runner/work/teapot/teapot/robot/teapot-v*-1.fc41.noarch.rpm .
RUN \
    adduser teapot && \
    rpm -i teapot-v*.noarch.rpm --nodeps
# certificates
WORKDIR /var/lib/teapot/webdav/
ADD --chown=teapot https://syncandshare.desy.de/index.php/s/AT4LMp9qJ3yxs9x/download/teapot.crt .
ADD --chown=teapot https://syncandshare.desy.de/index.php/s/zY6agLE29TAtkke/download/teapot.key .

# configuring teapot for testing
WORKDIR /etc/teapot
ADD https://syncandshare.desy.de/index.php/s/Gt7bEoNits4Sp9Z/download/storage-areas .
ADD https://syncandshare.desy.de/index.php/s/oEAQ6q4coPA82ag/download/user-mapping.csv .
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
EXPOSE 32400
EXPOSE 32401
EXPOSE 32402
EXPOSE 32403
EXPOSE 32404

WORKDIR /usr/share/teapot/
USER teapot

CMD python3 teapot.py