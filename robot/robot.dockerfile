# trunk-ignore-all(trivy/DS026)
FROM ubuntu:22.04

# hadolint ignore=DL3008,DL3013,DL3042
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates \
        curl \
        oidc-agent \
        python3-pip \
        gettext-base && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install robotframework robotframework-requests certifi-linux && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --chmod=644 Teapot-testing.crt /usr/local/share/ca-certificates
RUN update-ca-certificates