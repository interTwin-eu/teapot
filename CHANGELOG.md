# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased] - 2023-11.27

Teapot is now able to spawn StoRM-WebDAV instances by itself and route requests to the corresponding instances based on AuthN/Z via Openid-connect tokens.
It is, however, not able to terminate instances after the set timeout because the PIDs of the processes are not the ones of the originally spawned ones due to
spawning them for each user makes several forks necessary which changes the PID. 
TODO: Fix terminating instances.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).
 
## [Unreleased] - yyyy-mm-dd
 
Here we write upgrading notes for brands. It's a team effort to make them as straightforward as possible.
 
