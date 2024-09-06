# Configuration

## Certificates

Both Teapot and StoRM WebDAV servers require `SSL` certificates. Teapot requires
a certificate/key pair for the machine's DNS name to be added to `/var/lib/teapot/webdav`,
the certificate should also be added to the system's trust store. To generate self-signed
certificates for StoRM WebDAV and add them to the trust store, run
`sudo self-signed-cert-gen.sh`.

In `teapot.py` line 945, uvicorn hostname needs to be replaced with the machine DNS name,
and paths to the certificate/key pair for that DNS name should be added here.

## Storm-webdav configuration

Two main pieces of information are required to configure StoRM-WebDAV:

- Storage Areas (SA), which are folders assigned to each user
- OIDC provider and identity mapping information

### Storage areas (SA)

Storage areas that are automatically assigned to each user should be defined in the
`storage-areas` file. `storage-areas` file should be manually added to `/etc/teapot/`.
It should contain a list of storage areas and their root paths. The information for
each storage area should be on a single line, separated by a single space. It is used
to automatically create configuration files for users. Here is an example of
`storage-areas` file content:
```
default $HOME/interTwin
extra $HOME/interTwin_extra
```

For user-specific storage areas, configuration files must be created manually and
added to `/var/lib/teapot/user-$USER/sa/$SA_NAME.properties`.
Template for this can be found under `/templates/storage_element.properties` in
the repository or `/usr/share/teapot/storage_element.properties` upon installation,
where the information defined in `storage-areas` must be added manually, or you
can follow the principles of the .properties files that are automatically generated
for SA in the `storage-areas` file.

For information on how to configure storage-areas, please refer to the
[StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).

### OIDC provider and identity mapping information

OIDC provider information used to authenticate users must be provided. See below
for information on where to change the OIDC provider information. For more
details on authentication to the storage areas, refer to the
[StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).

To configure the OIDC provider information, make the following changes:

1. Modify the OIDC provider in `/etc/teapot/issuers` by changing the `name`
   and `issuer` information.
2. Modify the OIDC provider in `/usr/share/teapot/storage_authorizations` by
   modifying the `iss` information which stands for issuer.
3. Modify the OIDC providers that have access to the storage area by modifying
   the `org` information in `/usr/share/teapot/storage_element.properties`.
4. Modify the OIDC provider list in `teapot.py` under `flaat.set_trusted_OP_list`.

If no other way for mapping user's local and global identities is provided, the
rudementary way is defined as explained next. The `user-mapping.csv` file is to
be manually added to `/etc/teapot`. It should contain information for mapping local
users' identities to their global identities as provided by the OIDC provider in form
of the subject (`sub`) claim. For each user, the local username and the user's sub
claim from the OIDC provider should be on a single line, separated by a single space.
E.g.:

```
user1 subclaim1
user2 subclaim2
```

## System certificates

To run Teapot, OpenSSL certificates may need to be adjusted. To do this please do the
following: In `OPENSSLDIR`, which can be found with `openssl version -d`, create a
symbolic link to the system ca-trust-source by typing
`sudo ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem`.
The letsencrypt and geant/sectigo ca-certs may need to be added to the system
ca-trust-store `/etc/pki/ca-trust/source/anchors`, which is then updated using
`sudo update-ca-trust`.
