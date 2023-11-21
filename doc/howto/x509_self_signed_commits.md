# Using self-signed X.509 certificates for signed commits

GitLab supports the use of [signed commits using X.509 certificates](https://docs.gitlab.com/ee/user/project/repository/signed_commits/x509.html).
This tutorial creates a commit with a self signed X.509 certificate which is verified by the GDK. When complete the commit is displayed as verified on the commits page:<br>![Verified Commit](img/verified_commit.jpg)

To setup self-signed X.509 certificates for signed commits in GDK follow the steps below.
The commands can be run from any empty directory in the MacOS home folder unless otherwise specified.

1. [Prerequisites](#prerequisites)
1. [Create a CA cert](#create-a-ca-cert)
1. [Create an end-entity cert](#create-an-end-entity-cert)
1. [Import keys into gpgsm and add to trustlist](#import-keys-into-gpgsm-and-add-to-trustlist)
1. [Set up GDK to use the CA cert we generated](#set-up-gdk-to-use-the-ca-certificate-we-generated)
1. [Set up a project](#set-up-a-project)
1. [Cleaning Up](#cleaning-up)

## Prerequisites

<!-- markdownlint-disable MD029 -->

1. This tutorial requires openssl version 1.1. If your version is 3, it can be set to 1.1 by brew:

   ```shell
   brew unlink openssl@3
   ```

   ```shell
   brew link openssl@1.1 --force
   ```

## Create a CA cert

1.

   ```shell
   openssl genrsa -out ca.key 4096
   ```

1.

   ```shell
   openssl req \
     -new \
     -x509 \
     -subj "/C=US/ST=California/L=San Francisco/O=GitLab/OU=dev/CN=gdk.test/emailAddress=root@gdk.test" \
     -days 3650 \
     -key ca.key \
     -out ca.crt
   ```

## Create an end-entity cert

1.

   ```shell
   openssl genrsa -out git.key 4096
   ```

1.

   ```shell
   openssl req \
     -new \
     -subj "/C=US/ST=California/L=San Francisco/O=GitLab/OU=dev/CN=gdk.test/emailAddress=root@gdk.test" \
     -key git.key  \
     -out git.csr
   ```

1.

   ``` shell
   openssl x509 -req -days 3650 -in git.csr -CA ca.crt -CAkey ca.key -extfile <(
       echo "subjectAltName = DNS:gitlab.test,email:test@example.com,email:test2@example.com"; \
       echo "keyUsage = critical,digitalSignature"
       echo "subjectKeyIdentifier = hash"
       echo "authorityKeyIdentifier = keyid"
       echo "crlDistributionPoints=DNS:gitlab.test,URI:http://example.com/crl.pem"
   ) -set_serial 1 -out git.crt
   ```

## Import keys into gpgsm and add to trustlist

1.

   ``` shell
   openssl pkcs12 -export -inkey git.key -in git.crt -name test -out git.p12
   ```

2.

   ``` shell
   openssl pkcs12 -export -inkey ca.key -in ca.crt -name test2 -out ca.p12
   ```

3.

   ``` shell
   gpgsm --import ca.p12
   ```

4.

   ``` shell
   gpgsm --import git.p12
   ```

5. Add the sha1 fpr for the last two keys in `gpgsm --list-keys` to `~/.gnupg/trustlist.txt`:

   ```  shell
   gpgsm --list-keys | grep 'sha1 fpr' | awk -F 'sha1 fpr: ' '{ print $2 }' >> ~/.gnupg/trustlist.txt
   ```

6. Suppress [DirMngr checking for revoked certificates](https://gnupg.org/documentation/manuals/gnupg-2.0/Certificate-Options.html) by running:

   ```  shell
   echo "disable-crl-checks" >>  ~/.gnupg/gpgsm.conf
   ```

## Set up GDK to use the CA certificate we generated

1. In the GDK root directory:

   ```  shell
   echo "export SSL_CERT_FILE=<path-to-ca.crt>" >> env.runit
   ```

2. Restart the GDK:

   ```  shell
   gdk restart
   ```

3. In a Rails console:

   ```  shell
   Feature.enable(:x509_forced_cert_loading)
   ```

## Set up a project

1. Create a user with email <test2@example.com>.
1. Create a project.
1. Clone the project.
1. Configure the Git client to sign commits:

   ```  shell
   git config user.email test2@example.com
   ```

   ```  shell
   git config user.signingkey $(gpgsm --list-keys | grep 'ID: ' | tail -n1 | awk -F': ' '{ print $2 }')
   ```

   ```  shell
   git config gpg.program gpgsm
   ```

   ```  shell
   git config gpg.format x509
   ```

5. Restart gpg-agent:

   ```  shell
   gpgconf --kill gpg-agent
   ```

6. Make some changes and commit with signature:

   ```  shell
   echo test > test && git add test && git commit -m "test" -S
   ```

7. Push the changes.
8. Look at the commits just pushed (e.g <http://gdk.test:3000/root/test-signatures/-/commits/branch_name>) and see that there is a Verified badge next to the signed commit.

## Cleaning Up

Some of these configurations should be removed once testing is complete.

1. Remove added keys from gpgsm by running `gpgsm --list-keys` and find the last two key ids. Delete each of them by running `gpgsm --delete-keys <key id>`.
2. Remove the two sha1 fpr keys which were added to `~/.gnupg/trustlist.txt`.
3. Remove ignore crl setting from gpgsm.conf by deleting `disable-crl-checks` from `~/.gnupg/gpgsm.conf`.
4. Remove ssl cert file from GDK by deleting `export SSL_CERT_FILE=path to ca.crt` from `env.runit` and restarting the GDK: `gdk restart`.

<!-- markdownlint-enable MD029 -->
