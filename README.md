# Teapot

This application provides a WebDAV that supports multi-tenancy. It is based on [StoRM-WebDAV](https://github.com/italiangrid/storm-webdav). We have added a manager level that accepts requests, authenticates the user, identifies the local username of the user, starts a StoRM-WebDAV server for that local user with a randomly assigned port to listen on, and forwards the user's request to that port. The StoRM-WebDAV server will then handle the request in the usual way. If the StoRM-WebDAV server is inactive for 10 minutes, it will be shut down by the manager. If another request comes in for a different user, the manager will start another StoRM-WebDAV server for that user in the same way.

## Getting Started

### Requirements

Software requirements for installing Teapot can be found in [requirements.txt](https://github.com/interTwin-eu/teapot/blob/main/requirements.txt).

### Installation & Configuration

To install Teapot, first build the rpm package from source by running `./rpm/teapot-rpm.sh`, then install it.

Please refer to [CONFIGURATION.md](https://github.com/interTwin-eu/teapot/blob/main/CONFIGURATION.md) for information on how to configure Teapot.

### Starting

To start Teapot, run `python3 /usr/share/teapot/teapot.py`.

## Automated testing

Functional tests can be found in `/robot`. To execute them, run e.g. `robot teapot-tests.robot`.

## Version

The current version of Teapot is 0.5.0.

## Authors
[Paul Millar](mailto:paul.millar@desy.de), [Dijana Vrbanec](mailto:dijana.vrbanec@desy.de), [Tim Wetzel](mailto:tim.wetzel@desy.de)

## Acknowledgements

Teapot is a WebDAV solution that supports multi-tenancy. It is based on [StoRM-WebDAV](https://github.com/italiangrid/storm-webdav).