---
layout: page
title: Installation Guide
permalink: /installation_guide/
---

## Requirements

Teapot needs `Python3` to run, the specific distribution depends on the
operating system. The required Python packages for installing Teapot are
listed in the [requirements.txt](https://github.com/interTwin-eu/teapot/blob/main/requirements.txt)
file. Python packages that aren't available in the rpm format are already
included in Teapot's rpm file. To automatically generate self-signed
certificate `openssl>3` is needed. Storm-webdav needs `java-17`.

## Installation

Teapot can be installed via an RPM package. On the release page, we provide
RPMs for Fedora 39, AlmaLinux 9.4, and Rocky Linux 9.3. If you need an RPM
file for another Linux distribution, feel free to contact us and we’ll gladly
provide you with one for your specific Linux distribution.

To install Teapot, first a user `teapot` must be created. To do that run
 `sudo adduser teapot`.

Please refer to [Configuration](/teapot/configuration) for information on how
to configure Teapot and Storm-Webdav.

## Starting

Teapot starts automatically upon installation using a systemd unit file. Once
configured, you can restart the service with
`sudo systemctl restart teapot.service`. To ensure Teapot launches
automatically after each reboot, enable it with
`sudo systemctl enable teapot.service`.
