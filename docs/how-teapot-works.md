---
layout: page
title: How Teapot works
permalink: /how-teapot-works/
---

**Teapot** is open-source software providing HTTP/WebDAV access to existing
storage systems. It supports multi-tenancy and is built on top of
**StoRM-WebDAV**.

Teapot handles incoming requests by:

- Authenticating users  
- Resolving the local username based on the chosen identity mapping method  
- Launching a dedicated StoRM-WebDAV server instance per user on a dynamically
assigned port (if not already running)
- Forwarding user requests to the appropriate StoRM-WebDAV instance  

Each StoRM-WebDAV server processes requests normally. If inactive for 10
minutes, the server is automatically shut down by Teapot.

If a request arrives for a user with an active StoRM-WebDAV server, Teapot
forwards the request to the existing instance. Otherwise, it starts a new one.

---

## Workflow Overview

![Teapot workflow](/assets/Teapot-diagram.drawio.png)

Figure 1: Teapot's process for handling user requests

Upon receiving a request, Teapot authenticates the user and maps the global
identity to a local username. It then checks for an active StoRM-WebDAV server
for that user:

- If none exists, it starts a new server on an available port above 32400 on
localhost.
- Communication between Teapot and StoRM-WebDAV is encrypted.  
- Requests are forwarded to the user’s StoRM-WebDAV server, which interacts
with the storage and returns responses via Teapot.
- Requests from other users are handled similarly, starting new server instances
as needed.
- After 10 minutes of inactivity, StoRM-WebDAV servers are shut down to save
resources.

For more details on StoRM-WebDAV, see the [official documentation](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).

---

## Identity Mapping Methods

Teapot supports three identity mapping methods to resolve user identities:

### 1. File-based Mapping

User mappings are stored in a file with lines containing the local username and
the user's OIDC subject claim (`sub`), separated by a space.

Example:

```text
user1 248289761001
user2 a12b3c4d5e6f
```

### 2. ALISE (Account Linking Service)

Using [ALISE](https://github.com/m-team-kit/alise/tree/master/alise), users
link multiple global accounts to a single local account per site.

### 3. VO-based Mapping

All members of a Virtual Organization (VO) are mapped to a single local
identity. This is a group-based mapping approach.
