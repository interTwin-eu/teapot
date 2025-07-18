#!/bin/bash

: "${version_rpm:=0.0.0}"

#setting up a file tree for the RPM package in HOME directory
rpmdev-setuptree

#adding a spec file
cp rpm/teapot-fedora.spec "${HOME}"/rpmbuild/SPECS/

#getting the teapot scripts
mkdir teapot-"${version_rpm}"
rsync -av --progress ./* teapot-"${version_rpm}"/ --exclude teapot-"${version_rpm}"
tar cfz teapot-"${version_rpm}".tar.gz teapot-"${version_rpm}"
rm -r teapot-"${version_rpm}"
mv teapot-"${version_rpm}".tar.gz "${HOME}"/rpmbuild/SOURCES/

#getting the storm-webdav.jar file
curl -O https://repo.cloud.cnaf.infn.it/repository/storm-rpm-stable/redhat9/storm-webdav-1.8.1-1.el9.noarch.rpm
rpm2cpio storm-webdav-1.8.1-1.el9.noarch.rpm | cpio -id ./usr/share/java/storm-webdav/storm-webdav-server.jar || true
rm storm-webdav-1.8.1-1.el9.noarch.rpm
mv usr/share/java/storm-webdav/storm-webdav-server.jar ./
rm -r usr
tar cf storm-webdav-server.tar.gz storm-webdav-server.jar
rm storm-webdav-server.jar
mv storm-webdav-server.tar.gz "${HOME}"/rpmbuild/SOURCES/

cd /tmp || exit
curl -L -O https://syncandshare.desy.de/index.php/s/oSjdrPwCd6KkfJm/download/python-lib64-fedora.tar.gz
curl -L -O https://syncandshare.desy.de/index.php/s/PqN432X83764Lm4/download/python-lib-fedora.tar.gz
mv /tmp/python-lib*.tar.gz "${HOME}"/rpmbuild/SOURCES/

#building the RPM package
rpmbuild -ba --define "version_ ${version_rpm}" ~/rpmbuild/SPECS/teapot-fedora.spec
