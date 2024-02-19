FROM registry.access.redhat.com/ubi9 AS ubi-micro-build

RUN mkdir -p /mnt/rootfs

RUN dnf install --installroot /mnt/rootfs curl --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all

FROM quay.io/keycloak/keycloak:22.0.5

COPY --from=ubi-micro-build /mnt/rootfs /

ENV KEYCLOAK_ADMIN=admin 
ENV KEYCLOAK_ADMIN_PASSWORD=testing1 
ENV KC_HOSTNAME=keycloak 
ENV KC_HTTP_ENABLED=true 
ENV KC_HEALTH_ENABLED=true

WORKDIR /opt/keycloak/data/import/
ADD --chown=keycloak https://syncandshare.desy.de/index.php/s/byaGFbzNqYc4GrR/download/keycloak-export.json .
ADD https://syncandshare.desy.de/index.php/s/6rz5dLFD3NewHb2/download/keycloak.crt /etc/pki/tls/certs/
ADD https://syncandshare.desy.de/index.php/s/nK5LjNkb2eYKMni/download/keycloak.key /etc/pki/tls/certs/

CMD [ "start-dev --import-realm --https-certificate-file=/etc/pki/tls/certs/keycloak.crt --https-certificate-key-file=keycloak.key" ]

HEALTHCHECK --interval=10s --start-period=30s --retries=15 CMD curl --fail http://keycloak:8080 || exit 1

