#!/bin/bash
# This script is responsible for starting the StoRM WebDAV instance,
# It is expected that this script is run as the user the StoRM
# WebDAV should run under.
#
# This script will exit only once StoRM WebDAV is able to accept
# requests.

USER_DIR=/var/lib/teapot/user-"$USER"
STORM_DIR=/var/lib/teapot/webdav

HOST_IP="$(curl ifconfig.me)"
echo HOST_IP is "$HOST_IP"

echo "Starting StoRM WebDAV as user $USER"
export STORM_WEBDAV_JVM_OPTS="-Xms2048M -Xmx2048M -Djava.security.egd=file:/dev/./urandom"
export STORM_WEBDAV_SERVER_ADDRESS="$HOST_IP"
export STORM_WEBDAV_HTTPS_PORT=$port
export STORM_WEBDAV_HTTP_PORT=1$port 
export STORM_WEBDAV_CERTIFICATE_PATH=$STORM_DIR/localhost.crt
export STORM_WEBDAV_PRIVATE_KEY_PATH=$STORM_DIR/localhost.key
export STORM_WEBDAV_TRUST_ANCHORS_DIR=/etc/ssl/certs
export STORM_WEBDAV_TRUST_ANCHORS_REFRESH_INTERVAL=86400
export STORM_WEBDAV_MAX_CONNECTIONS=300
export STORM_WEBDAV_MAX_QUEUE_SIZE=900
export STORM_WEBDAV_CONNECTOR_MAX_IDLE_TIME=30000
export STORM_WEBDAV_SA_CONFIG_DIR=$USER_DIR/sa.d
export STORM_WEBDAV_JAR=/usr/share/java/storm-webdav/storm-webdav-server.jar

export STORM_WEBDAV_LOG=$USER_DIR/log/server.log
export STORM_WEBDAV_OUT=$USER_DIR/log/server.out
export STORM_WEBDAV_ERR=$USER_DIR/log/server.err

ETC_DIR=/etc/$name
export STORM_WEBDAV_LOG_CONFIGURATION=$ETC_DIR/logback.xml
export STORM_WEBDAV_ACCESS_LOG_CONFIGURATION=$ETC_DIR/logback-access.xml
export STORM_WEBDAV_VO_MAP_FILES_ENABLE=false
export STORM_WEBDAV_VO_MAP_FILES_REFRESH_INTERVAL=21600
export STORM_WEBDAV_TPC_MAX_CONNECTIONS=50
export STORM_WEBDAV_TPC_VERIFY_CHECKSUM=false
export STORM_WEBDAV_REQUIRE_CLIENT_CERT=false
export STORM_WEBDAV_TPC_USE_CONSCRYPT=true

strace -e trace=file -o /tmp/storm-webdav \
/usr/bin/java ${STORM_WEBDAV_JVM_OPTS} \
    -Djava.io.tmpdir=$USER_DIR/tmp \
    -Dlogging.config=${STORM_WEBDAV_LOG_CONFIGURATION} \
    -jar ${STORM_WEBDAV_JAR} >${STORM_WEBDAV_OUT} 2>${STORM_WEBDAV_ERR} \
    --spring.config.additional-location=optional:file:/var/lib/$name/user-$US$


pid=$!
echo "$pid" > "$USER_DIR"/server.pid
echo "$port" > "$USER_DIR"/server.port

#nc -zvw 1 "$STORM_WEBDAV_SERVER_ADDRESS" "$port" &> /dev/null
#status=$?
#while [ ! $status -eq 0 ]; do
#    echo -n .
#    sleep 0.5s
#    nc -zvw 1 "$STORM_WEBDAV_SERVER_ADDRESS" "$port" &> /dev/null
#    status=$?
#done

exit 0
