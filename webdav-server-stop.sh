#! /bin/bash

if [ $# -ne 1 ]; then
    echo "$0 USER"
    echo
    echo "USER is the name of the user under which to run StoRM WebDAV."
    exit 1
fi

USER="$1"

USER_DIR=/var/lib/teapot/user-$USER

pid=$(cat $USER_DIR/server.pid)

kill -15 $pid

rm $USER_DIR/server.pid
rm $USER_DIR/server.port
