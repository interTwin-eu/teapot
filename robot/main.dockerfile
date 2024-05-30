FROM ubuntu:22.04

RUN apt update && \
    apt install -y ca-certificates curl python3-pip && \
    pip install --upgrade pip && \
    pip install robotframework robotframework-requests 

WORKDIR /usr/local/share/ca-certificates
ADD https://syncandshare.desy.de/index.php/s/KY8ARPLQHzw2Fdm/download/Teapot-testing.crt .
ADD https://syncandshare.desy.de/index.php/s/Xb8djtiyXPrGboG/download/testingCA.pem .
RUN update-ca-certificates

RUN echo "deb [signed-by=/etc/apt/trusted.gpg.d/kitrepo-archive.gpg] https://repo.data.kit.edu//ubuntu/22.04 ./" >> /etc/apt/sources.list && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/kitrepo-archive.gpg] https://repo.data.kit.edu//ubuntu/jammy ./" >> /etc/apt/sources.list

RUN apt -y install oidc-agent

