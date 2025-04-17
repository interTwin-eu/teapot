# Configuration

All configuration settings are stored in the `config.ini` file, located at
`/etc/teapot/`. Update this file as needed to align with your requirements.

## Certificates

Both Teapot and StoRM WebDAV servers require `SSL` certificates. The certificate
must also be added to the system’s trust store to ensure secure communication.
To generate self-signed certificates for StoRM WebDAV and add them to the trust
store, run `sudo /usr/share/teapot/self-signed-cert-gen.sh`.

## Additional Storm-webdav configuration

Two main pieces of additional information are required to configure StoRM-WebDAV:

- Storage Areas (SA), which are folders assigned to each user
- OIDC provider and identity mapping information

### Storage areas (SA)

Storage areas that are automatically assigned to each user should be defined in
the `storage-areas` file. `storage-areas` file should be manually added to
`/etc/teapot/`. It should contain a list of storage areas and their root paths.
The information for each storage area should be on a single line, separated by a
single space. It is used to automatically create configuration files for users.
Here is an example of `storage-areas` file content:

```text
default $HOME/interTwin
extra $HOME/interTwin_extra
```

For user-specific storage areas, configuration files must be created manually
and added to `/var/lib/teapot/user-$USER/sa/$SA_NAME.properties`. Template for
this can be found under `/templates/storage_element.properties` in the
repository or `/usr/share/teapot/storage_element.properties` upon installation,
where the information defined in `storage-areas` must be added manually, or you
can follow the principles of the .properties files that are automatically
generated for SA in the `storage-areas` file.

For information on how to configure storage-areas, please refer to the
[StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).

### OIDC provider and identity mapping information

OIDC provider information used to authenticate users must be provided. See below
for information on where to change the OIDC provider information, besides the
changes already made in `config.ini` file. For more details on authentication to
the storage areas, refer to the [StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).

To configure the OIDC provider information, make the following changes:

1. Modify the OIDC provider in `/etc/teapot/issuers` by changing the `name` and
   `issuer` information.
2. Modify the OIDC provider in `/usr/share/teapot/storage_authorizations` by
   modifying the `iss` information which stands for issuer.
3. Modify the OIDC providers that have access to the storage area by modifying
   the `org` information in `/usr/share/teapot/storage_element.properties`.

All users must be added to the `teapot` group. This can be done by running
`usermod -a -G teapot $USERNAME`.

## Mapping user’s global and local identities

### File-based Mapping Method

Teapot provides three methods for mapping a user’s global and local identities.
The first method is the **File-based Mapping Method**. Teapot allows manual
storage of user mappings in a file named `user-mapping.csv`, which must be
placed in `/etc/teapot`. This file should contain the following information:
for each user, the local username and the user's OIDC subject claim (sub),
as provided by the Identity Provider (IdP). These values must be listed on a
single line, separated by a single space.

Example:

```text
user1 248289761001
user2 a12b3c4d5e6f
```

### ALISE - Account Linking Serice

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

Also, in the `/templates/storage_authorizations` file — which will be placed in
`/usr/share/teapot/` — the authorization must be updated:

- Change `jwt-subject` to `jwt-issuer`.
- Remove the line containing `sub = $sub`.

## System certificates

To run Teapot, OpenSSL certificates may need to be adjusted. To do this please
do the following: In `OPENSSLDIR`, which can be found with `openssl version -d`,
create a symbolic link to the system ca-trust-source by typing
`sudo ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem`. The
letsencrypt and geant/sectigo ca-certs may need to be added to the system
ca-trust-store `/etc/pki/ca-trust/source/anchors`, which is then updated using
`sudo update-ca-trust`.
