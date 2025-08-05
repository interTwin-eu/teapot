# Configuration

All configuration settings are stored in the `config.ini` file, located at
`/etc/teapot/`. Update this file to configure Teapot according to your
requirements.

## Certificates

Both Teapot and StoRM WebDAV servers require `SSL` certificates. The certificate
must also be added to the system’s trust store to ensure secure communication.
Path to the Teapot's certificate should be specified in `config.ini`.
To generate self-signed certificates for StoRM WebDAV and add them to the trust
store, run `sudo /usr/share/teapot/self-signed-cert-gen.sh`.

## Storm-webdav configuration files

### Storage areas

Teapot uses a pre-configured template for storage area configuration.
It can be found at:

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
refer to the [StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md)
for detailed instructions.

## Mapping user’s global and local identities

### File-based Mapping Method

Teapot provides three methods for mapping a user’s global and local identities.
The first method is the **File-based Mapping Method**. Teapot allows manual
storage of user mappings in a file. This file should contain the following
information: for each user, the local username and the user's OIDC subject
claim (sub), as provided by the Identity Provider (IdP). These values must
be listed on a single line, separated by a single space.

Example:

```text
user1 248289761001
user2 a12b3c4d5e6f
```

### ALISE - Account Linking Service

The second method uses the **ALISE - Account Linking Service**
([ALISE documentation](https://github.com/m-team-kit/alise/tree/master/alise)).
ALISE allows users to log in with a single local account per site while linking
multiple global accounts.

To configure ALISE you must specify:

- The ALISE instance that manages the required mappings.
- The computing center where local identities should be mapped.

To access ALISE's API, you first need to obtain an API key. This can be done
via the following endpoint: `ALISE_INSTANCE + /api/v1/target/{site}/get_apikey`.
The API key is associated with a specific user and is obtained using an Access
Token. You can retrieve the API key via a `curl` request by including the Access
Token in the request header:

```bash
curl -H "Authorization: Bearer ${ACCESS_TOKEN}" <API_ENDPOINT>
```

### VO based mapping

The third method is **VO-based mapping**, where all members of a Virtual Organization
(VO) are mapped to a single local identity. This is a **group-based mapping** approach.

To configure VO-based mapping, specify:

- The `eduperson-entitlement` that defines the VO membership.
- The local account to which users with the matching `eduperson-entitlement` will be
   mapped.
