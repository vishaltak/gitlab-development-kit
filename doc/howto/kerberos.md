# Kerberos

In order to test Kerberos integration with your GDK, you need to have a working
Kerberos server.

## Requirements

Install [Docker](https://docs.docker.com/get-docker/) and
[Docker Compose](https://docs.docker.com/compose/install/).

## Setting up integration with GDK

1. Run `docker-compose up` in `kerberos/` directory. This will build a docker
   image and start a container with a Kerberos KDC for `EXAMPLE.COM` realm.
1. Copy the `http.keytab` generated in the container:

   ```shell
   $ docker cp <container ID or name>:/etc/http.keytab <GDK directory>/kerberos
   ```

   Example:

   ```shell
   $ docker cp kerberos_krb5_1:/etc/http.keytab /home/user/gdk/kerberos
   ```

   This keytab will then be used by GitLab to authenticate Kerberos users.
1. Ensure `http.keytab` is readable only by the user of your GDK.

   Example (`git` as the GDK user):

   ```shell
   $ chown git /home/user/gdk/kerberos/http.keytab
   $ chmod 0600 /home/user/gdk/kerberos/http.keytab
   ```

1. Configure `config/gitlab.yml` following the instructions from Kerberos
   integration [documentation](https://docs.gitlab.com/ee/integration/kerberos.html).
   The `keytab` option should point to where `http.keytab` exists.
1. Restart GDK: `gdk restart`.

## Adding a user principal

1. Access the KDC shell and enter `kadmin`:

   ```shell
   $ docker-compose exec krb5 bash
   $ kadmin.local
   ```

1. Create user principal that will be linked to a GitLab user account:

   ```shell
   addprinc <username>
   ```

   Example:

   ```shell
   addprinc user
   ```

   You'll be asked to enter and re-enter password.
1. Create an identity for a user you want to associate with the user principal
   via Rails console.

   ```shell
   Identity.create(user: User.find_by(username: 'user'), extern_uid: 'user@EXAMPLE.COM', provider: 'kerberos')
   ```

## Authenticating with Kerberos

To be able to get a Kerberos ticket, configure the client so it can find the
appropriate KDC for a specific realm.

1. Run `kinit` to get a ticket:

   ```shell
   $ kinit user@EXAMPLE.COM
   ```

   You'll be asked to enter the password set for the specified user principal.

1. Confirm that you got a ticket by running `klist`. You should see something like:

   ```shell
   $ klist
   $ Credentials cache: API:ABCDEFGH-1234-ABCD-1234-ABCDEFGHIJKL
             Principal: user@EXAMPLE.COM

       Issued                Expires               Principal
     Nov  6 18:13:08 2020  Nov  7 04:13:05 2020  krbtgt/EXAMPLE.COM@EXAMPLE.COM
   ```

1. Test that you can clone a repository without any credentials:

   ```shell
   $ git clone http://:@gitlab.example.com:3000/root/gitlab.git
   ```

   If you encounter a `HTTP Basic: Access denied` error, configure `git` to set
   `http.emptyAuth` to `true`.
