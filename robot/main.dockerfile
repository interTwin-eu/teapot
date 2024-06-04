FROM ubuntu:22.04

RUN apt update && \
    apt install -y ca-certificates curl python3-pip && \
    pip install --upgrade pip && \
    pip install robotframework robotframework-requests 

WORKDIR /usr/local/share/ca-certificates
ADD https://syncandshare.desy.de/index.php/s/KY8ARPLQHzw2Fdm/download/Teapot-testing.crt .
RUN update-ca-certificates

WORKDIR /usr/local/lib/python3.10/dist-packages/certifi/
RUN \
    rm -f cacert.pem && \
    ln -s /etc/ssl/certs/ca-certificates.crt cacert.pem

RUN echo "deb [signed-by=/etc/apt/trusted.gpg.d/kitrepo-archive.gpg] https://repo.data.kit.edu//ubuntu/22.04 ./" >> /etc/apt/sources.list && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/kitrepo-archive.gpg] https://repo.data.kit.edu//ubuntu/jammy ./" >> /etc/apt/sources.list

RUN apt -y install oidc-agent
