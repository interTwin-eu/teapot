Name:           teapot
Version:        %{version_}
Release:        1%{?dist}
Summary:        A WebDAV solution supporting multitenancy based on StoRM-WebDAV
BuildArch:      noarch

License:        Apache 2.0
URL:            https://github.com/interTwin-eu/%name
Source0:        %name-%version.tar.gz
Source1:        storm-webdav-server.tar.gz
Source2:        https://syncandshare.desy.de/index.php/s/SYF66KoeW9mTQc8/download/python-lib64.tar.gz
Source3:        https://syncandshare.desy.de/index.php/s/eHS5Q5CKmoWPPNo/download/python-lib.tar.gz
Requires:       java-11-openjdk python(abi) >= 3.0 python3-fastapi python3-httpx python3-pydantic python3-requests python3-uvicorn python3-anyio python3-psutil

%description    
A WebDAV solution supporting multitenancy based on StoRM-WebDAV

%define __jar_repack %{nil}
#%define _python_bytecompile_errors_terminate_build 0

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
mkdir -p %{buildroot}/%{_datadir}/%name/
cp %{_builddir}/%name-%version/teapot.py %{buildroot}/%{_datadir}/%name/
mkdir -p %{buildroot}/%{_sysconfdir}/%name
cp %{_builddir}/%name-%version/templates/issuers %{buildroot}/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/templates/logback.xml %{buildroot}/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/templates/logback-access.xml %{buildroot}/%{_sysconfdir}/%name/
mkdir -p %{buildroot}/%{_sysconfdir}/sudoers.d/
cp %{_builddir}/%name-%version/templates/teapot %{buildroot}/%{_sysconfdir}/sudoers.d/
mkdir -p %{buildroot}/%{_datadir}/%name
cp %{_builddir}/%name-%version/templates/storage_authorizations %{buildroot}/%{_datadir}/%name
cp %{_builddir}/%name-%version/templates/storage_element.properties %{buildroot}/%{_datadir}/%name
mkdir -p %{buildroot}/%{_sharedstatedir}/%name/webdav
cp %{_builddir}/%name-%version/templates/teapot_sessions.json %{buildroot}/%{_sharedstatedir}/%name/webdav/teapot_sessions.json
mkdir -p %{buildroot}/%{_localstatedir}/log/%name/
cp %{_builddir}/%name-%version/templates/teapot.log %{buildroot}/%{_localstatedir}/log/%name/
cp %{_builddir}/%name-%version/templates/uvicorn.log %{buildroot}/%{_localstatedir}/log/%name/
mkdir -p %{buildroot}/%{_sysconfdir}/storm/webdav/vo-mapfiles.d/
mkdir -p %{buildroot}/%{_sysconfdir}/grid-security/vomsdir/
mkdir -p %{buildroot}/%{_prefix}/lib/systemd/system/
cp %{_builddir}/%name-%version/teapot.service %{buildroot}/%{_prefix}/lib/systemd/system/
mkdir -p %{buildroot}/%{_exec_prefix}/local/lib64/python3.12/site-packages/
cp %{_builddir}/%name-%version//%{_exec_prefix}/local/lib64/python3.12/site-packages/* %{buildroot}/%{_exec_prefix}/local/lib64/python3.12/site-packages/
mkdir -p %{buildroot}/%{_exec_prefix}/local/lib/python3.12/site-packages/
cp %{_builddir}/%name-%version//%{_exec_prefix}/local/lib/python3.12/site-packages/* %{buildroot}/%{_exec_prefix}/local/lib/python3.12/site-packages/

%clean
rm -rf %{buildroot}

%files
%attr(644, root, root) %{_datadir}/java/storm-webdav/storm-webdav-server.jar
%attr(774, teapot, teapot) %{_datadir}/%name/teapot.py
%attr(644, root, root) %{_sysconfdir}/%name/issuers
%attr(744, teapot, teapot) %{_sysconfdir}/%name/logback.xml
%attr(744, teapot, teapot) %{_sysconfdir}/%name/logback-access.xml
%attr(644, root, root) %{_datadir}/%name/storage_authorizations
%attr(644, root, root) %{_datadir}/%name/storage_element.properties
%attr(755, teapot, teapot) %{_localstatedir}/log/%name/
%attr(644, teapot, teapot) %{_localstatedir}/log/%name/teapot.log
%attr(644, teapot, teapot) %{_localstatedir}/log/%name/uvicorn.log
%attr(440, root, root) %{_sysconfdir}/sudoers.d/teapot
%attr(775, teapot, teapot) %{_sharedstatedir}/%name/
%attr(664, teapot, teapot) %{_sharedstatedir}/%name/webdav/teapot_sessions.json
%attr(775, teapot, teapot) %{_sharedstatedir}/%name/webdav
%attr(774, teapot, teapot) %{_sysconfdir}/storm/webdav/vo-mapfiles.d/
%attr(775, root, root) %{_sysconfdir}/grid-security/vomsdir/
%attr(774, root, root) %{_prefix}/lib/systemd/system/teapot.service
%attr(755, root, root) %{_exec_prefix}/local/lib/python3.12/site-packages/*
%attr(755, root, root) %{_exec_prefix}/local/lib/python3.12/site-packages/*

%changelog
* Wed Aug 28 2024 Dijana Vrbanec <dijana.vrbanec@desy.de>
- %{version}
