FROM fedora:41

USER root

RUN \
    dnf -y install initscripts java-11-openjdk && \
    dnf -y install perl-IPC-Cmd perl-Test-Simple && \
    dnf -y group install "Development Tools" && \
    dnf -y install tar jq unzip && \
    dnf -y install rpmdevtools rpmlint rsync && \
    dnf -y install libffi libffi-devel openssl && \
    dnf -y install python3.12 python3-pip && \
    pip install --upgrade pip && \
    pip install pydantic httpx logging uvicorn requests flaat==1.1.18 fastapi anyio  && \
    pip install asyncio psutil robotframework robotframework-requests python-keycloak

WORKDIR /usr/local/ssl
RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem

WORKDIR /etc/pki/ca-trust/source/anchors
ADD https://letsencrypt.org/certs/isrgrootx1.pem .
ADD https://letsencrypt.org/certs/lets-encrypt-r3.pem .
ADD http://crl.usertrust.com/USERTrustRSACertificationAuthority.crl .
ADD http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt .
ADD https://syncandshare.desy.de/index.php/s/KY8ARPLQHzw2Fdm/download/Teapot-testing.crt .
RUN update-ca-trust 

# WORKDIR /usr/local/lib/python3.12/site-packages/certifi/
# RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cacert.pem

# installing teapot
WORKDIR /tmp
ADD https://syncandshare.desy.de/index.php/s/bJXG9MSNLY45JLz/download/teapot-v0.5.0-1.fc41.noarch.rpm .
RUN \
    adduser teapot && \
    # unzip teapot-rpm.zip && \
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