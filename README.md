# Teapot

Teapot provides a multi-tenant WebDAV service based on
[StoRM-WebDAV](https://github.com/italiangrid/storm-webdav).

A manager layer accepts incoming requests, authenticates the user, determines
the corresponding local username, and starts a StoRM-WebDAV server instance for
that user. Each instance listens on a randomly assigned port, and the manager
forwards the user’s requests to that port.

If a StoRM-WebDAV server is inactive for 10 minutes, it is shut down by the
manager. When a request arrives for a different user, a new StoRM-WebDAV server
instance is started in the same way.

## Getting Started

### Requirements

The required Python packages are listed in
[`requirements.txt`](https://github.com/interTwin-eu/teapot/blob/main/requirements.txt).
Python packages that are not available as system packages are bundled in the
RPM and DEB packages.

To automatically generate self-signed certificates, `openssl >= 3` is required.
StoRM-WebDAV requires `Java 21`.

### Installation & Configuration

Teapot can be installed using either an **RPM** or **DEB** package.

- **DEB package:** Automatically creates a dedicated `teapot` system user. Distribution-independent.
- **RPM package:** Available for Fedora 39, AlmaLinux 9.4, and Rocky Linux 9.3. The system user must currently be created manually.


For configuration details, please refer to [CONFIGURATION.md](https://github.com/interTwin-eu/teapot/blob/main/CONFIGURATION.md),
which covers both Teapot and StoRM-WebDAV.

### Starting the Service

Teapot is started automatically upon installation via a systemd unit. After configuration,
you can restart the service with: `sudo systemctl restart teapot.service`.
To ensure Teapot starts automatically after each reboot, enable the service:
`sudo systemctl enable teapot.service`.

## Automated testing

Functional tests can be found in `/robot`. To execute them, run `robot teapot-tests.robot`.

## Version

The current version of Teapot is 0.20.0, and it uses Storm-Webdav version 1.12.0.

## Authors

[Paul Millar](mailto:paul.millar@desy.de),
[Dijana Vrbanec](mailto:dijana.vrbanec@desy.de),
[Tim Wetzel](mailto:tim.wetzel@desy.de)

## Acknowledgements

Teapot is a WebDAV solution that supports multi-tenancy. It is based on
[StoRM-WebDAV](https://github.com/italiangrid/storm-webdav).
