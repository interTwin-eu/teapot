FROM fedora:39

USER root

RUN \
    dnf -y install initscripts java-11-openjdk && \
    dnf -y install perl-IPC-Cmd perl-Test-Simple && \
    dnf -y group install "Development Tools" && \
    dnf -y install jq unzip && \
    dnf -y install libffi libffi-devel openssl && \
    dnf -y install python3-pip && \
    pip install --upgrade pip && \
    pip install pydantic httpx logging uvicorn requests flaat==1.1.18 && \
    pip install fastapi anyio asyncio psutil robotframework robotframework-requests python-keycloak

WORKDIR /usr/local/ssl
RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem

WORKDIR /etc/pki/ca-trust/source/anchors
ADD  --chmod=744 https://letsencrypt.org/certs/isrgrootx1.pem .
ADD  --chmod=744 https://letsencrypt.org/certs/lets-encrypt-r3.pem .
ADD  --chmod=744 http://crl.usertrust.com/USERTrustRSACertificationAuthority.crl .
ADD  --chmod=744 http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt .
RUN update-ca-trust 

WORKDIR /usr/local/lib/python3.12/site-packages/certifi/
RUN \
    rm -f cacert.pem && \
    ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cacert.pem

USER nobody