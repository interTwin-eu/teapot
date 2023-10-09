#!/bin/bash

#set -x

if [ `whoami` != "root" ]; then
    echo "This script MUST be run as root."
    exit 2
fi

if [ $# -ne 2 ]; then
    echo "$0 USER PORT"
    echo "Usage:"
    echo "USER is the name of the user under which to run StoRM WebDAV."
    echo "PORT is the network TCP port on which WebDAV will listen."
    exit 1
fi

export USER="$1"
export port="$2"
export name=teapot

echo "StoRM-WebDAV instance for user $USER will be listening on the port $port"

#creation of user-specific configuration directories
USER_DIR=/var/lib/$name/user-$USER
if [ ! -d $USER_DIR ]; then
    mkdir -p $USER_DIR
    chown $USER $USER_DIR
    echo "$USER_DIR was created as a directory for user $USER"
fi

# creation of the log directory for a new user
if [ ! -d $USER_DIR/log ]; then
    mkdir -p $USER_DIR/log
    chown $USER $USER_DIR/log
    echo "$USER_DIR/log was created"
fi

#creation of storage-properties files and folders for a new user
CONFIG_DIR=/etc/$name
if [ ! -f $CONFIG_DIR/storage-areas ]; then
    echo "Error: $CONFIG_DIR/storage-areas file is missing."
    echo "It should consist of two variables per storage area: name of the storage area and root path to the storage area's directory separated by a single space." 
    exit 1
fi

TEMPL_DIR=/usr/share/$name
if [ ! -d $USER_DIR/sa.d ]; then
    mkdir -p $USER_DIR/sa.d
    cat $CONFIG_DIR/storage-areas | while read storage_area path; do \
        echo -e  "name=$storage_area\nrootPath=$(su $USER -c "echo $path")\naccessPoints=/${storage_area}_area\n\n" >> $USER_DIR/sa.d/$storage_area.properties \
        && cat $TEMPL_DIR/storage_element.properties >> $USER_DIR/sa.d/$storage_area.properties \
        && chown $USER $USER_DIR/sa.d/$storage_area.properties \
        && chmod g+w $USER_DIR/sa.d/$storage_area.properties \
        && mkdir -p "$(su $USER -c "echo \"$path\"")" \
        && chown $USER "$(su $USER -c "echo \"$path\"")" \
    ; done
    chown $USER $USER_DIR/sa.d
    echo "Storage configuration was created at $USER_DIR/sa.d"
fi

#creation of the token authorization files
if [ ! -f $CONFIG_DIR/user-mapping.csv ]; then
    echo "Error: $CONFIG_DIR/user-mapping.csv file is missing."
    echo "It should consist of two variables per user: username and subject claim separated by a single space." 
    exit 1
fi

if [ ! -d $USER_DIR/config ]; then
    mkdir -p $USER_DIR/config
    grep "$USER" $CONFIG_DIR/user-mapping.csv | while read user_id sub; do \
        cat $CONFIG_DIR/issuers.yml >> $USER_DIR/config/application.yml \
        && echo -e "storm:\n  authz:\n    policies:" >> $USER_DIR/config/application.yml \
        && cat $CONFIG_DIR/storage-areas | while read storage_area path; do \
            export sub storage_area \
            && envsubst < $TEMPL_DIR/storage_authorizations.yml >> $USER_DIR/config/application.yml \
    ; done; done
    chown $USER $USER_DIR/config/application.yml
    chown $USER $USER_DIR/config
    echo "Authorization configuration was created for user $USER"
fi

#creation of the work directory $USER_DIR/tmp for a new user
if [ ! -d $USER_DIR/tmp ]; then
    mkdir -p $USER_DIR/tmp
    chown $USER $USER_DIR/tmp
    echo "$USER_DIR/tmp was created"
fi

su -c /usr/share/$name/webdav-server-start.sh $USER 
