FROM quay.io/keycloak/keycloak:26.0.2 AS builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_HTTPS_CERTIFICATE_FILE=/etc/pki/tls/certs/keycloak.pem
ENV KC_HTTPS_CERTIFICATE_KEY_FILE=/etc/pki/tls/certs/keycloak-key.pem

# Add certificates
COPY --chown=1000:0 keycloak.pem /etc/pki/tls/certs/
COPY --chown=1000:0 keycloak-key.pem /etc/pki/tls/certs/

# Build optimized image
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.0.2
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Runtime environment variables
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_BOOTSTRAP_ADMIN_USERNAME=admin
ENV KC_BOOTSTRAP_ADMIN_PASSWORD=testing1
ENV KC_HOSTNAME=keycloak
ENV KC_HTTPS_CERTIFICATE_FILE=/etc/pki/tls/certs/keycloak.pem
ENV KC_HTTPS_CERTIFICATE_KEY_FILE=/etc/pki/tls/certs/keycloak-key.pem

# Copy certificates to runtime image
COPY --from=builder /etc/pki/tls/certs/ /etc/pki/tls/certs/
COPY --chown=1000:0 keycloakdb.mv.db /opt/keycloak/data/h2/

# Add import file
WORKDIR /opt/keycloak
USER keycloak
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start-dev"]