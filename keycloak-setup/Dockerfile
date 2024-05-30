FROM registry.access.redhat.com/ubi9 AS ubi-micro-build

RUN mkdir -p /mnt/rootfs

RUN dnf install --installroot /mnt/rootfs curl --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all

FROM quay.io/keycloak/keycloak:22.0.5

COPY --from=ubi-micro-build /mnt/rootfs /

ENV KEYCLOAK_ADMIN=admin 
ENV KEYCLOAK_ADMIN_PASSWORD=testing1 
ENV KC_HOSTNAME=keycloak
ENV KC_HEALTH_ENABLED=true

WORKDIR /opt/keycloak/data/import/
ADD --chown=1000:0 https://syncandshare.desy.de/index.php/s/byaGFbzNqYc4GrR/download/keycloak-export.json .
ADD --chown=1000:0 https://syncandshare.desy.de/index.php/s/WXK5Qwrw882bytg/download/keycloak.pem /etc/pki/tls/certs/
ADD --chown=1000:0 https://syncandshare.desy.de/index.php/s/ZxjmXAeH76q9jtQ/download/keycloak-key.pem /etc/pki/tls/certs/

CMD [" start-dev --import-realm --https-certificate-file=/etc/pki/tls/certs/keycloak.pem --https-certificate-key-file=/etc/pki/tls/certs/keycloak-key.pem "]