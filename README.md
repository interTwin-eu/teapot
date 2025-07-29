# Teapot

This application provides a WebDAV that supports multi-tenancy. It is based on
[StoRM-WebDAV](https://github.com/italiangrid/storm-webdav). We have added a
manager level that accepts requests, authenticates the user, identifies the
local username of the user, starts a StoRM-WebDAV server for that local user
with a randomly assigned port to listen on, and forwards the user's request to
that port. The StoRM-WebDAV server will then handle the request in the usual
way. If the StoRM-WebDAV server is inactive for 10 minutes, it will be shut down
by the manager. If another request comes in for a different user, the manager
will start another StoRM-WebDAV server for that user in the same way.

## Getting Started

### Requirements

Teapot needs `Python3` to run, the specific distribution depends on the operating system.
The required Python packages for installing Teapot are listed in the [requirements.txt](https://github.com/interTwin-eu/teapot/blob/main/requirements.txt)
file. Python packages that aren't available in the rpm format are already included in Teapot's rpm file.
To automatically generate self-signed certificate `openssl>3` is needed. Storm-webdav needs `java-17`.

### Installation & Configuration

Teapot can be installed via an RPM package. On the release page, we provide RPMs for Fedora 39,
AlmaLinux 9.4, and Rocky Linux 9.3. If you need an RPM file for another Linux distribution,
feel free to contact us and we’ll gladly provide you with one for your specific Linux distribution.

To install teapot, first a user `teapot` must be created. To do that run `sudo adduser teapot`.

Please refer to [CONFIGURATION.md](https://github.com/interTwin-eu/teapot/blob/main/CONFIGURATION.md)
for information on how to configure Teapot and Storm-Webdav.

### Starting

Teapot starts automatically upon installation using a systemd unit file. Once configured, you can
restart the service with `sudo systemctl restart teapot.service`. To ensure Teapot launches automatically
after each reboot, enable it with `sudo systemctl enable teapot.service`.

## Automated testing

Functional tests can be found in `/robot`. To execute them, run `robot teapot-tests.robot`.

## Version

The current version of Teapot is 0.17.0, and it uses Storm-Webdav version 1.8.1.

## Authors

[Paul Millar](mailto:paul.millar@desy.de),
[Dijana Vrbanec](mailto:dijana.vrbanec@desy.de),
[Tim Wetzel](mailto:tim.wetzel@desy.de)

## Acknowledgements

Teapot is a WebDAV solution that supports multi-tenancy. It is based on
[StoRM-WebDAV](https://github.com/italiangrid/storm-webdav).
