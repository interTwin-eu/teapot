# Teapot

This application provides a WebDAV that supports multi-tenancy. It is based on [StoRM-WebDAV](https://github.com/italiangrid/storm-webdav). We have added a manager level that accepts requests, authenticates the user, identifies the local username of the user, starts a StoRM-WebDAV server for that local user with a randomly assigned port to listen on, and forwards the user's request to that port. The StoRM-WebDAV server will then handle the request in the usual way. If the StoRM-WebDAV server is inactive for 10 minutes, it will be shut down by the manager. If another request comes in for a different user, the manager will start another StoRM-WebDAV server for that user in the same way. 

## Getting Started

### Requirements

Software requirements for installing Teapot can be found in [requirements.txt](https://gitlab.desy.de/intertwin/teapot/-/blob/main/requirements.txt?ref_type=heads).

### Installation & Configuration

To install Teapot, first build the rpm package from source by running `./rpm/teapot-rpm.sh`, then install it. 

Please refer to [CONFIGURATION.md](https://gitlab.desy.de/intertwin/teapot/-/blob/main/CONFIGURATION.md?ref_type=heads) for information on how to configure Teapot. 

### Starting

To start Teapot, run `python3 /usr/share/teapot.py`.

## Automated testing

Functional tests can be found in `/robot`. Tests for testing the StoRM WebDAV server automatization only are separated into `storm-webdav-tests.robot` and tests for testing Teapot as a whole are separated into `teapot-tests.robot`. To execute them, run e.g. `robot teapot-tests.robot`.

## Version

The current version of Teapot is 0.0.1.

## Authors
[Paul Millar](<paul.millar@desy.de>), [Dijana Vrbanec](dijana.vrbanec@desy.de), [Tim Wetzel](tim.wetzel@desy.de)

## Acknowledgements

Teapot is a WebDAV solution that supports multi-tenancy. It is based on [StoRM-WebDAV](https://github.com/italiangrid/storm-webdav).