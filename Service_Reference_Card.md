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

All templates for configuration files are located in `/templates`. All
configuration files for each user are automatically generated in
`/var/lib/teapot/user-$USER/` when user sends its first request. To provide the
necessary information for configuration files and for more details on
configuration files, please refer to
[CONFIGURATION.md](https://github.com/interTwin-eu/teapot/blob/main/CONFIGURATION.md).

`teapot.py` has to be run as the user `teapot` (create if necessary) with the
python modules installed from `requirements.txt` and with the sudoers
permissions from the file `templates/teapot`.

## Log files

Teapot log files for WebDAV traffic can be found in `teapot-proxy.log`. Log
files for each user can be found in `/var/lib/teapot/user-$USER/log/`. Templates
for user log files can be found in `/templates`.

## List of ports

Teapot listens on port 8081. It will proxy WebDAV servers to listen to any open
port greater than 8081.

## List of cron jobs

If you plan to run the `self-signed-cert-gen.sh` script to generate the `SSL`
certificates, the script will trigger a cron job to automatically renew the
certificate once a year.
