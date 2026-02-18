FROM ubuntu:24.04

# hadolint ignore=DL3008,DL3013
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip gunicorn curl && \
    python3 -m pip install certifi-linux alise --break-system-packages --no-cache-dir

COPY --chmod=644 Teapot-testing.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

RUN mkdir -p /etc/alise/
COPY ./alise.conf /etc/alise/


WORKDIR /usr/local/lib/python3.12/dist-packages/alise
COPY --chmod=644 alise_keycloak_test.db .
COPY --chmod=744 starting-script.sh .

EXPOSE 8000

CMD ["./starting-script.sh"]