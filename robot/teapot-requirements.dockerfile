FROM fedora:39

USER root

RUN \
    dnf -y install initscripts java-17-openjdk perl-IPC-Cmd perl-Test-Simple && \
    dnf -y group install "Development Tools" && \
    dnf -y install libffi libffi-devel cronie openssl python3-pip && \
    dnf -y install python3-fastapi python3-httpx python3-pydantic && \
    dnf -y install python3-uvicorn python3-anyio python3-psutil python3-dotenv && \
    dnf clean all

WORKDIR /usr/local/ssl
RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem

WORKDIR /etc/pki/ca-trust/source/anchors
ADD  --chmod=744 https://letsencrypt.org/certs/isrgrootx1.pem .
ADD  --chmod=744 https://letsencrypt.org/certs/lets-encrypt-r3.pem .
ADD  --chmod=744 http://crl.usertrust.com/USERTrustRSACertificationAuthority.crl .
ADD  --chmod=744 http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt .
RUN update-ca-trust 
