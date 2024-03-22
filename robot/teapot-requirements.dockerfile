FROM fedora:41

USER root

RUN \
    dnf -y install initscripts java-11-openjdk && \
    dnf -y install perl-IPC-Cmd perl-Test-Simple && \
    dnf -y group install "Development Tools" && \
    dnf -y install unzip && \
    dnf -y install libffi libffi-devel openssl && \
    dnf -y install python3.12 python3-pip && \
    pip install --upgrade pip && \
    pip install pydantic httpx logging uvicorn requests flaat==1.1.18 && \
    pip install fastapi anyio asyncio psutil python-keycloak

WORKDIR /usr/local/ssl
RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem

WORKDIR /etc/pki/ca-trust/source/anchors
ADD https://letsencrypt.org/certs/isrgrootx1.pem .
ADD https://letsencrypt.org/certs/lets-encrypt-r3.pem .
ADD http://crl.usertrust.com/USERTrustRSACertificationAuthority.crl .
ADD http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt .
RUN update-ca-trust 

# WORKDIR /usr/local/lib/python3.12/site-packages/certifi/
# RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cacert.pem

