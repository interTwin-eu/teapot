# Service Reference Card

Teapot provides a WebDAV that supports multi-tenancy. It is based on
[StoRM-WebDAV](https://github.com/italiangrid/storm-webdav). We have added a
manager level that accepts requests, authenticates the user, identifies the
user's local username, starts a StoRM-WebDAV server for that local user with a
randomly assigned port to listen on, and forwards the user's request to that
port. The StoRM-WebDAV server will then handle the request in the usual way. If
the StoRM-WebDAV server is inactive for 10 minutes, it will be shut down by the
manager. If another request comes in for a different user, the manager will
start another StoRM-WebDAV server for that user in the same way.

## List of configuration files

All templates for configuration files are located in `/templates`. Teapot
configuration file can be found in `/etc/teapot/`. All configuration files for
StoRM-WebdDAV for each user are automatically generated in
`/var/lib/teapot/user-$USER/` when user sends its first request. To provide the
necessary information for configuration files and for more details on
configuration files, please refer to [CONFIGURATION.md](https://github.com/interTwin-eu/teapot/blob/main/CONFIGURATION.md).

`teapot.py` must be run as the `teapot` user, with the Python modules listed in
`requirements.txt` and the sudoers permissions defined in the `templates/teapot` file.
Teapot is started by systemd using the `teapot.service` file.

## Log files

Upon installation, Teapot log files can be found in `/var/log/teapot/`. Configuration
files for StoRM-WebDAV user log files can be found in `/etc/teapot/`.

## List of ports

Teapot listens on port 8081.

## List of cron jobs

If you run the `self-signed-cert-gen.sh` script to generate the self-signed
certificates for StoRM-WebDAV, the script will trigger a cron job to automatically
renew the certificate once a year.
