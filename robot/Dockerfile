FROM centos:centos7

USER root

RUN \
    yum -y update && \
    yum -y install epel-release redhat-lsb-core yum-utils && \
    yum -y install initscripts java-11-openjdk && \
    yum -y install perl-IPC-Cmd perl-Test-Simple && \
    yum -y group install "Development Tools" && \
    yum -y install tar jq-1.6 sudo

WORKDIR /usr/src
ADD https://www.openssl.org/source/openssl-3.0.12.tar.gz .
RUN \
    tar -zxf openssl-3.0.12.tar.gz && \
    rm openssl-3.0.12.tar.gz

WORKDIR /usr/src/openssl-3.0.12 
RUN \
    ./config && \
    make && \
    make install && \
    ln -s /usr/local/lib64/libssl.so.3 /usr/lib64/libssl.so.3 && \
    ln -s /usr/local/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3 && \
    ln -s /usr/local/bin/openssl /usr/bin/openssl

WORKDIR /tmp
ADD https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz .
RUN \
    tar -xzf Python-3.10.12.tgz && \
    rm Python-3.10.12.tgz && \
    yum -y install libffi libffi-devel zlib-devel

WORKDIR /tmp/Python-3.10.12/
RUN \
    ./configure --enable-optimizations && \
    make clean && \
    make install && \
    echo "export PATH=\"\${PATH}:/usr/local/lib/python3.10/site-packages\"" >> ~/.bashrc && \
    pip3 install --upgrade pip && \
    pip3 install pydantic && \
    pip3 install httpx && \
    pip3 install logging && \
    pip3 install uvicorn && \
    pip3 install requests && \
    pip3 install flaat && \
    pip3 install fastapi && \
    pip3 install anyio && \
    pip3 install asyncio && \
    pip3 install psutil && \
    pip3 install robotframework && \
    pip3 install robotframework-requests && \
    pip3 install python-keycloak

WORKDIR /tmp
ADD https://repo.data.kit.edu//data-kit-edu-centos7.repo /etc/yum.repos.d/data-kit-edu-centos7.repo
RUN \
    yum -y install oidc-agent && \
    yum -y update  && \
    yum clean all

WORKDIR /usr/local/ssl
RUN ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem

WORKDIR /etc/pki/ca-trust/source/anchors
ADD https://letsencrypt.org/certs/isrgrootx1.pem .
ADD https://letsencrypt.org/certs/lets-encrypt-r3.pem .
ADD http://crt.comodoca.com/USERTrustRSACertificationAuthority.crt .
ADD http://crt.usertrust.com/USERTrustRSAAddTrustCA.crt .
RUN update-ca-trust 

WORKDIR /usr/local/lib/python3.10/site-packages/certifi/
RUN rm cacert.pem && \
    ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cacert.pem

# for testing
RUN yum -y install rpmdevtools rpmlint rsync tree nano

RUN adduser teapot
WORKDIR /home/teapot/

EXPOSE 8081
EXPOSE 32400
EXPOSE 32401
EXPOSE 32402
EXPOSE 32403
EXPOSE 32404

