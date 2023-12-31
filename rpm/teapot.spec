Name:           teapot
Version:        v0.5.0
Release:        1%{?dist}
Summary:        A WebDAV solution supporting multitenancy based on StoRM-WebDAV
BuildArch:      noarch

License:        Apache 2.0
Source0:        teapot-%version.tar.gz
Source1:        storm-webdav-server.tar.gz
Requires:       attr ntp acl java-11-openjdk openssl > 3 nc python3 python3-fastapi python3-flaat python3-httpx python3-liboidcagent python3-logging python3-pydantic python3-regex python3-requests python3-uvicorn python3-anyio python3-asyncio

%description    
A WebDAV solution supporting multitenancy based on StoRM-WebDAV

%define __jar_repack %{nil}
#%define _python_bytecompile_errors_terminate_build 0

%prep
%setup
%setup -T -D -a 1

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/java/storm-webdav
cp %{_builddir}/%name-%version/storm-webdav-server.jar $RPM_BUILD_ROOT/%{_datadir}/java/storm-webdav/storm-webdav-server.jar
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/%name/
cp %{_builddir}/%name-%version/teapot.py $RPM_BUILD_ROOT/%{_datadir}/%name/
cp %{_builddir}/%name-%version/run-teapot.sh $RPM_BUILD_ROOT/%{_datadir}/%name/
cp %{_builddir}/%name-%version/self-signed-cert-gen.sh $RPM_BUILD_ROOT/%{_datadir}/%name/
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/%name
cp %{_builddir}/%name-%version/templates/issuers.yml $RPM_BUILD_ROOT/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/templates/logback.xml $RPM_BUILD_ROOT/%{_sysconfdir}/%name/
cp %{_builddir}/%name-%version/templates/logback-access.xml $RPM_BUILD_ROOT/%{_sysconfdir}/%name/
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/sudoers.d/
cp %{_builddir}/%name-%version/templates/teapot $RPM_BUILD_ROOT/%{_sysconfdir}/sudoers.d/
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/%name
cp %{_builddir}/%name-%version/templates/storage_authorizations.yml $RPM_BUILD_ROOT/%{_datadir}/%name
cp %{_builddir}/%name-%version/templates/storage_element.properties $RPM_BUILD_ROOT/%{_datadir}/%name
mkdir -p $RPM_BUILD_ROOT/%{_sharedstatedir}/%name/webdav
cp %{_builddir}/%name-%version/templates/teapot.log $RPM_BUILD_ROOT/%{_sharedstatedir}/%name/webdav
mkdir -p $RPM_BUILD_ROOT/%{_localstatedir}/run/%name
cp %{_builddir}/%name-%version/templates/teapot_sessions.json $RPM_BUILD_ROOT/%{_localstatedir}/run/%name/teapot_sessions.json

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(644, root, root) %{_datadir}/java/storm-webdav/storm-webdav-server.jar
%attr(755, root, root) %{_datadir}/%name/run-teapot.sh
%attr(777, root, root) %{_datadir}/%name/teapot.py
%attr(744, root, root) %{_datadir}/%name/self-signed-cert-gen.sh
%attr(644, root, root) %{_sysconfdir}/%name/issuers.yml
%attr(744, root, root) %{_sysconfdir}/%name/logback.xml
%attr(744, root, root) %{_sysconfdir}/%name/logback-access.xml
%attr(644, root, root) %{_datadir}/%name/storage_authorizations.yml
%attr(644, root, root) %{_datadir}/%name/storage_element.properties
%attr(666, teapot, teapot) %{_sharedstatedir}/%name/webdav/teapot.log
%attr(440, root, root) %{_sysconfdir}/sudoers.d/teapot
%attr(664, teapot, teapot) %{_localstatedir}/run/%name/teapot_sessions.json
%attr(774, teapot, teapot) %{_sharedstatedir}/%name/webdav

%changelog
* Mon Dec 04 2023 Dijana Vrbanec <dijana.vrbanec@desy.de>
- %{version}
