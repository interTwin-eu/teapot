---
layout: page
title: Installation
permalink: /installation-guide/
---

## Requirements

Teapot needs `Python3` to run, the specific distribution depends on the
operating system. The required Python packages for installing Teapot are
listed in the [requirements.txt](https://github.com/interTwin-eu/teapot/blob/main/requirements.txt)
file. Python packages that aren't available in the rpm format are already
included in Teapot's rpm file. To automatically generate self-signed
certificate `openssl>3` is needed. Storm-webdav needs `java-21`.

## Installation

Teapot can be installed using either an **RPM** or **DEB** package.

- **DEB package:** Automatically creates a dedicated `teapot` system user. Distribution-independent.
- **RPM package:** Available for Fedora 39, AlmaLinux 9.4, and Rocky Linux 9.3. The system user must currently be created manually.

For configuration details, please refer to [Configuration](/teapot/configuration),
which covers both Teapot and StoRM-WebDAV.

## Starting

Teapot starts automatically upon installation using a systemd unit file. Once
configured, you can restart the service with
`sudo systemctl restart teapot.service`. To ensure Teapot launches
automatically after each reboot, enable it with
`sudo systemctl enable teapot.service`.
