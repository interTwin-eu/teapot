Name:           teapot
Version:        %{version_}
Release:        1%{?dist}
Summary:        A WebDAV solution supporting multitenancy based on StoRM-WebDAV
BuildArch:      x86_64

License:        Apache 2.0
URL:            https://github.com/interTwin-eu/%name
Source0:        %name-%version.tar.gz
BuildRequires:  systemd-rpm-macros python3-pip wget rpm-build cpio
Requires:       java-21-openjdk openssl >= 1:3.0 python(abi) = 3.9 python3-psutil python3-requests shadow-utils

%description    
Multi-tenant WebDAV server based on StoRM-WebDAV.
Teapot provides a WebDAV server that supports multi-tenancy. It is based on
StoRM-WebDAV and adds a manager level that accepts requests, authenticates
users, identifies local usernames, and starts a StoRM-WebDAV server for each
user with a randomly assigned port.
The StoRM-WebDAV server handles requests in the usual way. If inactive for
10 minutes, the server is shut down by the manager. When another request
comes in for a different user, the manager starts another StoRM-WebDAV
server for that user in the same way.
Python packages not available as RPM (flaat, certifi-linux, fastapi, httpx,
pydantic, uvicorn, anyio, python-dotenv) are automatically installed during
package installation.

%define __jar_repack %{nil}
%global debug_package %{nil}

%prep
%setup

%build
# Download storm-webdav JAR (version from environment or default)
STORM_VERSION=%{?storm_version}%{!?storm_version:1.12.0}
if [ ! -f storm-webdav-server.jar ]; then
    wget https://repo.cloud.cnaf.infn.it/repository/storm-rpm-stable/redhat9/storm-webdav-${STORM_VERSION}-1.el9.noarch.rpm -O storm-webdav.rpm
    rpm2cpio storm-webdav.rpm | cpio -idmv
    cp usr/share/java/storm-webdav/storm-webdav-server.jar .
    rm -rf usr storm-webdav.rpm
fi

# Install Python packages with pip (including all their dependencies)
mkdir -p python-packages
pip3 install --target=python-packages --ignore-installed 'flaat>=1.1.18' certifi-linux fastapi httpx pydantic uvicorn anyio python-dotenv

%install
rm -rf %{buildroot}

# Storm WebDAV JAR
mkdir -p %{buildroot}/%{_datadir}/java/storm-webdav
cp storm-webdav-server.jar %{buildroot}/%{_datadir}/java/storm-webdav/

# Application files
mkdir -p %{buildroot}/%{_datadir}/%name
cp teapot.py %{buildroot}/%{_datadir}/%name/
cp alise.py %{buildroot}/%{_datadir}/%name/
cp vo_mapping.py %{buildroot}/%{_datadir}/%name/
cp self-signed-cert-gen.sh %{buildroot}/%{_datadir}/%name/

# Configuration files
mkdir -p %{buildroot}/%{_sysconfdir}/%name
cp templates/application.yml.template %{buildroot}/%{_sysconfdir}/%name/
cp templates/storage_area.properties.template %{buildroot}/%{_sysconfdir}/%name/
cp templates/logback.xml %{buildroot}/%{_sysconfdir}/%name/
cp templates/logback-access.xml %{buildroot}/%{_sysconfdir}/%name/
cp config.ini %{buildroot}/%{_sysconfdir}/%name/
cp user_config.ini %{buildroot}/%{_sysconfdir}/%name/

# Sudoers
mkdir -p %{buildroot}/%{_sysconfdir}/sudoers.d/
cp templates/teapot %{buildroot}/%{_sysconfdir}/sudoers.d/

# Directories
mkdir -p %{buildroot}/%{_sharedstatedir}/%name/webdav
mkdir -p %{buildroot}/%{_localstatedir}/log/%name/
mkdir -p %{buildroot}/%{_sysconfdir}/storm/webdav/vo-mapfiles.d/
mkdir -p %{buildroot}/%{_sysconfdir}/grid-security/vomsdir/

# Systemd service
mkdir -p %{buildroot}/%{_unitdir}
cp teapot.service %{buildroot}/%{_unitdir}/

# Python packages to application-specific directory (avoids all conflicts)
mkdir -p %{buildroot}/%{_datadir}/%name/python-packages
cp -r python-packages/* %{buildroot}/%{_datadir}/%name/python-packages/

# Create .pth file to add application packages to Python path
mkdir -p %{buildroot}/usr/lib/python3.9/site-packages/
echo "/usr/share/teapot/python-packages" > %{buildroot}/usr/lib/python3.9/site-packages/teapot.pth

%clean
rm -rf %{buildroot}

%pre
# Create teapot user before installation
getent group teapot >/dev/null || groupadd -r teapot
getent passwd teapot >/dev/null || \
    useradd -r -g teapot -d %{_sharedstatedir}/%name -s /sbin/nologin \
    -c "Teapot Service User" teapot
exit 0

%post
# Set ownership after files are installed
chown -R teapot:teapot %{_sharedstatedir}/%name
chown -R teapot:teapot %{_localstatedir}/log/%name
chown -R teapot:teapot %{_sysconfdir}/%name
chown -R teapot:teapot %{_datadir}/%name

# Systemd
%systemd_post teapot.service

%preun
%systemd_preun teapot.service

%postun
if [ $1 -eq 0 ] ; then
    # Complete uninstall
    %systemd_postun_with_restart teapot.service
    userdel teapot 2>/dev/null || :
    groupdel teapot 2>/dev/null || :
    rm -rf %{_sharedstatedir}/%name
    rm -rf %{_localstatedir}/log/%name
fi

%files
%attr(644, root, root) %{_datadir}/java/storm-webdav/storm-webdav-server.jar
%attr(744, teapot, teapot) %{_datadir}/%name/teapot.py
%attr(644, teapot, teapot) %{_datadir}/%name/alise.py
%attr(664, teapot, teapot) %{_datadir}/%name/vo_mapping.py
%attr(774, root, root) %{_datadir}/%name/self-signed-cert-gen.sh
%attr(644, root, root) %{_sysconfdir}/%name/application.yml.template
%attr(644, root, root) %{_sysconfdir}/%name/storage_area.properties.template
%attr(644, teapot, teapot) %{_sysconfdir}/%name/logback.xml
%attr(644, teapot, teapot) %{_sysconfdir}/%name/logback-access.xml
%attr(644, teapot, teapot) %{_sysconfdir}/%name/config.ini
%attr(644, teapot, teapot) %{_sysconfdir}/%name/user_config.ini
%attr(755, teapot, teapot) %dir %{_localstatedir}/log/%name/
%attr(440, root, root) %{_sysconfdir}/sudoers.d/teapot
%attr(777, teapot, teapot) %dir %{_sharedstatedir}/%name/
%attr(755, teapot, teapot) %dir %{_sharedstatedir}/%name/webdav
%attr(774, teapot, teapot) %{_sysconfdir}/storm/webdav/vo-mapfiles.d/
%attr(775, root, root) %{_sysconfdir}/grid-security/vomsdir/
%attr(664, root, root) %{_unitdir}/teapot.service
%attr(755, teapot, teapot) %dir %{_datadir}/%name/python-packages
%{_datadir}/%name/python-packages/*
%attr(644, root, root) /usr/lib/python3.9/site-packages/teapot.pth

%changelog
* Wed Feb 04 2026 Dijana Vrbanec <dijana.vrbanec@desy.de>
- %{version}