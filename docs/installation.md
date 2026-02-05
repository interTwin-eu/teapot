---
layout: page
title: Installation
permalink: /installation-guide/
---

## Requirements

Teapot requires `Python 3` to run; the exact distribution depends on the operating
system. The Python packages required to install Teapot are listed in the
[requirements.txt](https://github.com/interTwin-eu/teapot/blob/main/requirements.txt)
file.
Python dependencies that are not available as system packages are bundled with the
Teapot packages (both RPM and Debian). To automatically generate and renew
self-signed certificates, OpenSSL ≥ 3 and a cron service are required.
Storm-webdav needs `java-21`.

## Installation

Teapot can be installed using either an **RPM** or **DEB** package.
A dedicated `teapot` system user is automatically created during installation.

- **DEB package:** Distribution-independent.
- **RPM package:** Available for Fedora 39, AlmaLinux 9.4, and Rocky Linux 9.3.

For configuration details, please refer to [Configuration](/teapot/configuration),
which covers both Teapot and StoRM-WebDAV.

## Starting

Teapot starts automatically upon installation using a systemd unit file. Once
configured, you can restart the service with
`sudo systemctl restart teapot.service`.
