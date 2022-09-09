# Verifying OTP release integrity

All OTP releases are cryptographically signed, to allow
you to verify the integrity if you choose to.

Releases are signed with [Signify](https://man.openbsd.org/signify.1),
with [the public key in the main repository](https://akkoma.dev/AkkomaGang/akkoma/src/branch/develop/SIGNING_KEY.pub)

Release URLs will always be of the form

```
https://akkoma-updates.s3-website.fr-par.scw.cloud/{branch}/akkoma-{flavour}.zip
```

Where branch is usually `stable` or `develop`, and `flavour` is
the one [that you detect on install](../otp_en/#detecting-flavour).

So, for an AMD64 stable install, your update URL will be

```
https://akkoma-updates.s3-website.fr-par.scw.cloud/stable/akkoma-amd64.zip
```

To verify the integrity of this file, we have two helper files

```
# Checksums
https://akkoma-updates.s3-website.fr-par.scw.cloud/{branch}/akkoma-{flavour}.zip.sha256

# Signify signature of the hashes
https://akkoma-updates.s3-website.fr-par.scw.cloud/{branch}/akkoma-{flavour}.zip.sha256.sig
```

Thus, to upgrade manually, with integrity checking, consider the following script:

```bash
#!/bin/sh
set -eo pipefail

export FLAVOUR=amd64
export BRANCH=stable

# Fetch signing key
wget https://akkoma.dev/AkkomaGang/akkoma/src/branch/develop/SIGNING_KEY.pub -o AKKOMA_SIGNING_KEY.pub

# Download zip file and sig files
wget https://akkoma-updates.s3-website.fr-par.scw.cloud/$BRANCH/akkoma-$FLAVOUR{.zip,.zip.sha256,.zip.sha256.sig}

# Verify zip file's sha256 integrity
sha256sum --check akkoma-$FLAVOUR.zip.sha256

# Verify hash file's integrity
signify -V -p AKKOMA_SIGNING_KEY.pub -m akkoma-$FLAVOUR.zip.sha256.sig

# We're good, use that URL
./bin/pleroma_ctl update --zip-url https://akkoma-updates.s3-website.fr-par.scw.cloud/$BRANCH/akkoma-$FLAVOUR.zip
```
