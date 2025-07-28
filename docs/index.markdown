---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: home
title: Teapot
---

Teapot is open-source software that allows HTTP/WebDAV access to your
existing storage. It supports multi-tenancy and it's based on StoRM-WebDAV.
We have added a manager level that accepts requests, authenticates the user,
identifies the local username of the user, starts a StoRM-WebDAV server for
that local user with a randomly assigned port to listen on, and forwards the
user's request to that port. The StoRM-WebDAV server will then handle the
request in the usual way. If the StoRM-WebDAV server is inactive for 10 minutes,
it will be shut down by the manager. If another request comes in or a different
user, the manager will start another StoRM-WebDAV server for that user in the same
way.

*This website is under update, and more information will come soon.*
