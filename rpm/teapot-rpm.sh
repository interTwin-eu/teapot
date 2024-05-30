#!/bin/bash

export version=v0.5.0

#setting up a file tree for the RPM package in home directory
rpmdev-setuptree

#adding a spec file
cp rpm/teapot.spec "$HOME"/rpmbuild/SPECS/

#getting the teapot scripts
mkdir teapot-"$version"
rsync -av --progress /* teapot-"$version"/ --exclude teapot-"$version"
tar cfz teapot-"$version".tar.gz teapot-"$version"
rm -r teapot-"$version"
mv teapot-"$version".tar.gz "$HOME"/rpmbuild/SOURCES/

#getting the storm-webdav.jar file
curl -O https://repo.cloud.cnaf.infn.it/repository/storm-rpm-stable/centos7/storm-webdav-1.4.2-1.el7.noarch.rpm
rpm2cpio storm-webdav-1.4.2-1.el7.noarch.rpm | cpio -id ./usr/share/java/storm-webdav/storm-webdav-server.jar
rm storm-webdav-1.4.2-1.el7.noarch.rpm
mv usr/share/java/storm-webdav/storm-webdav-server.jar ./
rm -r usr
tar cf storm-webdav-server.tar.gz storm-webdav-server.jar
rm storm-webdav-server.jar
mv storm-webdav-server.tar.gz "$HOME"/rpmbuild/SOURCES/

#building the RPM package
rpmbuild -ba ~/rpmbuild/SPECS/teapot.spec
