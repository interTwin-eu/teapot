Name:           teapot
Version:        %{version_}
Release:        1%{?dist}
Summary:        A WebDAV solution supporting multitenancy based on StoRM-WebDAV
BuildArch:      x86_64

License:        Apache 2.0
URL:            https://github.com/interTwin-eu/%name
Source0:        %name-%version.tar.gz
Source1:        storm-webdav-server.tar.gz
Source2:        https://syncandshare.desy.de/index.php/s/nsCALcFF3JAnW9j/download/python-lib64-rocky1.tar.gz
Source3:        https://syncandshare.desy.de/index.php/s/y2y95e8BTxrqyZG/download/python-lib-rocky1.tar.gz
BuildRequires:  systemd-rpm-macros
Requires:       java-17-openjdk openssl >= 1:3.0 python(abi) = 3.9 python3-psutil python3-requests

%description    
Teapot provides a WebDAV that supports multi-tenancy. It is based on StoRM-WebDAV. We have added a manager level that
accepts requests, authenticates the user, identifies the local username of the user, starts a StoRM-WebDAV server
for that local user with a randomly assigned port to listen on, and forwards the user's request to that port.
The StoRM-WebDAV server will then handle the request in the usual way. If the StoRM-WebDAV server is inactive for
10 minutes, it will be shut down by the manager. If another request comes in for a different user, the manager will
start another StoRM-WebDAV server for that user in the same way.

%define __jar_repack %{nil}
%global debug_package %{nil}

%prep
%setup
%setup -T -D -a 1
%setup -T -D -a 2
%setup -T -D -a 3

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{_datadir}/java/storm-webdav
cp %{_builddir}/%name-%version/storm-webdav-server.jar %{buildroot}/%{_datadir}/java/storm-webdav/storm-webdav-server.jar
mkdir -p %{buildroot}/%{_datadir}/%name
cp %{_builddir}/%name-%version/teapot.py %{buildroot}/%{_datadir}/%name/
cp %{_builddir}/%name-%version/alise.py %{buildroot}/%{_datadir}/%name/
cp %{_builddir}/%name-%version/vo_mapping.py %{buildroot}/%{_datadir}/%name/
cp %{_builddir}/%name-%version/self-signed-cert-gen.sh %{buildroot}/%{_datadir}/%name/
mkdir -p %{buildroot}/%{_sysconfdir}/%name
cp %{_builddir}/%name-%version/templates/application.yml.template %{buildroot}/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/templates/storage_area.properties.template %{buildroot}/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/templates/logback.xml %{buildroot}/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/templates/logback-access.xml %{buildroot}/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/config.ini %{buildroot}/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/user_config.ini %{buildroot}/%{_sysconfdir}/%name/
mkdir -p %{buildroot}/%{_sysconfdir}/sudoers.d/
cp %{_builddir}/%name-%version/templates/teapot %{buildroot}/%{_sysconfdir}/sudoers.d/
mkdir -p %{buildroot}/%{_sharedstatedir}/%name/webdav
mkdir -p %{buildroot}/%{_localstatedir}/log/%name/
cp %{_builddir}/%name-%version/templates/teapot.log %{buildroot}/%{_localstatedir}/log/%name/
cp %{_builddir}/%name-%version/templates/uvicorn.log %{buildroot}/%{_localstatedir}/log/%name/
mkdir -p %{buildroot}/%{_sysconfdir}/storm/webdav/vo-mapfiles.d/
mkdir -p %{buildroot}/%{_sysconfdir}/grid-security/vomsdir/
mkdir -p %{buildroot}/%{_unitdir}
cp %{_builddir}/%name-%version/teapot.service %{buildroot}/%{_unitdir}/
mkdir -p %{buildroot}/%{_exec_prefix}/local/lib64/python3.9/site-packages/
cp -r %{_builddir}/%name-%version//%{_exec_prefix}/local/lib64/python3.9/site-packages/* %{buildroot}/%{_exec_prefix}/local/lib64/python3.9/site-packages/
mkdir -p %{buildroot}/%{_exec_prefix}/local/lib/python3.9/site-packages/
cp -r %{_builddir}/%name-%version//%{_exec_prefix}/local/lib/python3.9/site-packages/* %{buildroot}/%{_exec_prefix}/local/lib/python3.9/site-packages/

%clean
rm -rf %{buildroot}

%post
if [ $1 -gt 1 ] ; then
    %systemd_post teapot.service
fi

%preun
%systemd_preun teapot.service

%postun
if [ $1 -eq 0 ] ; then
    %systemd_postun_with_restart teapot.service
fi

%files
%attr(644, root, root) %{_datadir}/java/storm-webdav/storm-webdav-server.jar
%attr(774, teapot, teapot) %{_datadir}/%name/teapot.py
%attr(774, teapot, teapot) %{_datadir}/%name/alise.py
%attr(774, teapot, teapot) %{_datadir}/%name/vo_mapping.py
%attr(774, root, root) %{_datadir}/%name/self-signed-cert-gen.sh
%attr(644, root, root) %{_sysconfdir}/%name/application.yml.template
%attr(644, root, root) %{_sysconfdir}/%name/storage_area.properties.template
%attr(744, teapot, teapot) %{_sysconfdir}/%name/logback.xml
%attr(744, teapot, teapot) %{_sysconfdir}/%name/logback-access.xml
%attr(744, teapot, teapot) %{_sysconfdir}/%name/config.ini
%attr(744, teapot, teapot) %{_sysconfdir}/%name/user_config.ini
%attr(755, teapot, teapot) %{_localstatedir}/log/%name/
%attr(644, teapot, teapot) %{_localstatedir}/log/%name/teapot.log
%attr(644, teapot, teapot) %{_localstatedir}/log/%name/uvicorn.log
%attr(440, root, root) %{_sysconfdir}/sudoers.d/teapot
%attr(775, teapot, teapot) %{_sharedstatedir}/%name/
%attr(775, teapot, teapot) %{_sharedstatedir}/%name/webdav
%attr(774, teapot, teapot) %{_sysconfdir}/storm/webdav/vo-mapfiles.d/
%attr(775, root, root) %{_sysconfdir}/grid-security/vomsdir/
%attr(774, root, root) %{_unitdir}/teapot.service
%attr(755, root, root) %{_exec_prefix}/local/lib64/python3.9/site-packages/*
%attr(755, root, root) %{_exec_prefix}/local/lib/python3.9/site-packages/*

%changelog
* Fri May 09 2025 Dijana Vrbanec <dijana.vrbanec@desy.de>
- %{version}
