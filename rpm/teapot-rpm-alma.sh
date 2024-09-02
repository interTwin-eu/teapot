#!/bin/bash

#setting up a file tree for the RPM package in home directory
rpmdev-setuptree

#adding a spec file
cp rpm/teapot-alma.spec "$HOME"/rpmbuild/SPECS/

#getting the teapot scripts
mkdir teapot-"$version_rpm"
rsync -av --progress * teapot-"$version_rpm"/ --exclude teapot-"$version_rpm"
tar cfz teapot-"$version_rpm".tar.gz teapot-"$version_rpm"
rm -r teapot-"$version_rpm"
mv teapot-"$version_rpm".tar.gz "$HOME"/rpmbuild/SOURCES/

#getting the storm-webdav.jar file
curl -O https://repo.cloud.cnaf.infn.it/repository/storm-rpm-stable/centos7/storm-webdav-1.4.2-1.el7.noarch.rpm
rpm2cpio storm-webdav-1.4.2-1.el7.noarch.rpm | cpio -id ./usr/share/java/storm-webdav/storm-webdav-server.jar
rm storm-webdav-1.4.2-1.el7.noarch.rpm
mv usr/share/java/storm-webdav/storm-webdav-server.jar ./
rm -r usr
tar cf storm-webdav-server.tar.gz storm-webdav-server.jar
rm storm-webdav-server.jar
mv storm-webdav-server.tar.gz "$HOME"/rpmbuild/SOURCES/

cd /tmp
curl -O https://syncandshare.desy.de/index.php/s/XN5T5aBZRByGXYj/download/python-lib64-alma.tar.gz .
curl -O https://syncandshare.desy.de/index.php/s/roALWCXRZ5AATSP/download/python-lib-alma.tar.gz .
mv /tmp/python-lib*.tar.gz "$HOME"/rpmbuild/SOURCES/

#building the RPM package
rpmbuild -ba --define "version_ $version_rpm" ~/rpmbuild/SPECS/teapot-alma.spec