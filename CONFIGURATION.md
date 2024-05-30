# Configuration

To configure Teapot, two main pieces of information are required: Storage Areas
(SA), which are folders assigned to each user, need to be defined. Storage areas
that are automatically assigned to each user should be defined in the
`storage-areas` file, which is explained in more detail below. For user specific
storage areas, configuration files must be created manually and added to
`/var/lib/teapot/user-$USER/sa/$SA_NAME.properties`. Template for this can be
found under `/templates/storage_element.properties`, where the information
defined in `storage-areas` must be added manually, or you can follow the
principles of the .properties files that are automatically generated for SA in
the `storage-areas` file. For information on how to configure storage-areas,
please refer to the
[StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).
OIDC provider information used to authenticate users must be provided. See below
for information on where to change the OIDC provider information. For more
details on authentication to the storage areas, refer to the
[StoRM WebDAV Guidelines](https://github.com/italiangrid/storm-webdav/blob/master/doc/storage-area-configuration.md).

Two files need to be manually added to `/etc/teapot/`: `storage-areas` and
`user-mapping.csv`.

The `storage-areas` file should contain a list of storage areas and their root
paths. The information for each storage area should be on a single line,
separated by a single space. It is used to automatically create configuration
files for users.

The `user-mapping.csv` file should contain information for mapping local users'
identities to their token's `sub` claim. The local username and sub for each
user should be on a single line, separated by a single space.

To configure the OIDC provider information, make the following changes:

1. Modify the OIDC provider in `issuers.yml` by changing the `name` and `issuer`
   information.
2. Modify the OIDC provider in `storage_authorizations.yml` by modifying the
   `iss` information which stands for issuer.
3. Modify the OIDC providers that have access to the storage area by modifying
   the `org` information in `storage_element.properties`.
4. Modify the OIDC provider list in `teapot.py` under
   `flaat.set_trusted_OP_list`.

StoRM WebDAV servers require `SSL` certificates. To generate self-signed
certificates, run `sudo self-signed-cert-gen.sh`.

To run Teapot, Python and OpenSSL certificates may need to be adjusted. To do
this please do the following: In `OPENSSLDIR`, which can be found with
`openssl version -d`, create a symbolic link to the system ca-trust-source by
typing `sudo ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem cert.pem`.
The letsencrypt and geant/sectigo ca-certs may need to be added to the system
ca-trust-store `/etc/pki/ca-trust/source/anchors`, which is then updated using
`sudo update-ca-trust`. For Python, another symlink needs to be created in the
directory that you get when running

```
import certifi
certifi.where()
```

using the same procedure as above.
