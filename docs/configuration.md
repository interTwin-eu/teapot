---
layout: page
title: Configuration
permalink: /configuration/
---

All configuration settings are stored in the `config.ini` file, located at
`/etc/teapot/`. To configure Teapot according to your requirements, follow the
instructions provided inside the file.

## Certificates

Both Teapot and StoRM WebDAV servers require SSL certificates. The path to
Teapot's certificate should be specified in `config.ini`. To generate
self-signed certificates for StoRM WebDAV and add them to the trust store,
run `sudo /usr/share/teapot/self-signed-cert-gen.sh`.

## StoRM WebDAV configuration files

Teapot automatically generates StoRM WebDAV configuration files for each
user from templates upon their first request. Below, you can find details
on how these configuration files are created and managed.

### Storage areas

Teapot uses a pre-configured template for storage area configuration, found at:

- Repository: `templates/storage_area.properties.template`
- Installation: `/etc/teapot/storage_area.properties.template`

For user-specific storage areas, configuration files must be created manually
and added to `/var/lib/teapot/user-<username>/sa/<storage_area>.properties`.

To make any changes to the template, please refer to the
[StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md)
for detailed instructions.

### Authorization Template

Teapot uses a template to define authorization to storage areas, found at:

- Repository: `templates/application.yml.template`
- Installation: `/etc/teapot/application.yml.template`

The template is pre-configured. To make any additional changes, please
refer to the [StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).

## Mapping user’s global and local identities

Teapot provides several methods for mapping a user’s global and local
identities.

### File-based mapping

The File-based mapping allows manual storage of user mappings in a file.
This file should contain the local username and the user's OIDC subject
claim (`sub`) as provided by the Identity Provider (IdP). Each entry must
be on a single line, with values separated by a single space.

Example:

```text
user1 248289761001
user2 a12b3c4d5e6f
```

### ALISE - Account Linking Service

The ALISE - Account Linking Service
([ALISE documentation](https://github.com/m-team-kit/alise/tree/master/alise))
allows users to log in with a single local account per site while linking
multiple global accounts.

To configure ALISE, specify:

- The ALISE instance that manages the required mappings.
- The computing center where local identities should be mapped.

To access ALISE's API, first obtain an API key via:
`ALISE_INSTANCE + /api/v1/target/{site}/get_apikey`.
The API key is associated with a specific user and obtained using an Access
Token. Retrieve the API key with a `curl` request, including the
Access Token in the header:

```bash
curl -H "Authorization: Bearer ${ACCESS_TOKEN}" <API_ENDPOINT>
```

### VO based mapping

VO-based mapping maps all members of a Virtual Organization (VO) to a single
local identity. This is a group-based mapping approach.

To configure VO-based mapping, specify:

- The `eduperson-entitlement` that defines VO membership.
- The local account to which users with the matching `eduperson-entitlement`
will be mapped.

### Keycloak-based mapping

Keycloak-based mapping maps the user's `sub` claim to Keycloak's
`preferred_username`. No additional configuration is needed.
