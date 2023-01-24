# GitLab Geo

This document instructs you to set up GitLab Geo using GDK.

Geo allows you to replicate a whole GitLab instance. Customers use this for
Disaster Recovery, as well as to offload read-only requests to secondary
instances. For more, see
[GitLab Geo](https://about.gitlab.com/solutions/geo/) or
[Replication (Geo)](https://docs.gitlab.com/ee/administration/geo/replication/).

## Easy installation

### How to install 2 GDKs and configure Geo

The installation script:

- Clones the GDK project into a new `gdk` directory in the current working directory.
- Installs `asdf` and necessary `asdf` plugins.
- Runs `gdk install`.
- Runs `gdk start`.
- Adds your license.
- Clones the GDK project into a new `gdk2` directory in the current working directory.
- Runs `./support/geo-add-secondary` (see below for a description of this script).

1. Follow the [dependency installation instructions](../index.md#install-prerequisites).

1. Set the `GITLAB_LICENSE_KEY` environment variable in your shell, with the text of a GitLab Premium or Ultimate license key.

   If you have a file on disk, then run:

   ```shell
   export GITLAB_LICENSE_KEY=$(cat /path/to/your/premium.gitlab-license)
   ```

   Or, if you have plaintext, then run:

   ```shell
   export GITLAB_LICENSE_KEY="pasted text"
   ```

1. Run the installation script:

   ```shell
   curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/geo-install" | bash
   ```

   Or, if you want to name the GDK directories, then run:

   ```shell
   curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/geo-install" | bash -s name-of-primary name-of-secondary
   ```

To check if it is working, visit the unified URL at `http://127.0.0.1:3001` and sign in. Your requests are always served by the secondary site (as if Geo-location based DNS is set up and you are located near the secondary site). It should behave no differently than the primary site. That is the goal anyway.

If needed, you can visit the primary directly at `http://127.0.0.1:3000` but this would be considered a workaround, and you may notice quirks. For example, absolute URLs rendered on the page use the unified URL. You may also occasionally get redirected to the unified URL.

To see if you are able to run tests, you can run a simple spec like `bin/rspec ee/spec/lib/gitlab/geo/logger_spec.rb` from the `gitlab` directory in the primary `gdk` directory.

## Advanced Installation

Please visit [GitLab Geo - Advanced Installation](geo/advanced_installation.md).

## Running tests

### On a primary

If you used an [easy installation](#easy-installation) method to configure Geo, then this has already been done on the primary.

The secondary has a read-write tracking database, which is necessary for some
Geo tests to run. However, its copy of the replicated database is read-only, so
tests fail to run.

You can add the tracking database to the primary node by running:

```shell
# From the gdk folder:
gdk start

# In another terminal window
make geo-setup
```

This adds both development and test instances, but the primary continues
to operate *as* a primary except in tests where the current Geo node has been
stubbed.

To ensure the tracking database is started, restart GDK. You need to use
`gdk start` to be able to run the tests.

### On a secondary

<!-- TODO: Add this to support/geo-add-secondary. Then the Running tests section can be moved into the Manual installation section. -->

When you try to run tests on a GDK configured as a Geo secondary, tests
might fail because the main database is read-only.

You can work around this by using the PostgreSQL instance that is used
for the tracking database (i.e. the one running in
`<secondary-gdk-root>/postgresql-geo`) for both the tracking and the
main database.

In `<secondary-gdk-root>/gitlab/config/database.yml`, add or replace the `test:` block with the following:

```yaml
test: &test
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_test
    host: /home/<secondary-gdk-root>/postgresql-geo
    port: 5432
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
  ci:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_test_ci
    host: /home/<secondary-gdk-root>/postgresql-geo
    port: 5432
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
```

## SSH cloning

If you used the [Easy installation](#easy-installation), then your primary site's SSH service is disabled, and your secondary site's SSH service is enabled. The listen port is unchanged. This simulates having a unified URL for SSH which happens to always route to the secondary site. With this setup, you can already observe Geo-specific behavior. For example, when you do a Git push, you will see `This request to a Geo secondary node will be forwarded to the Geo primary node`.

You can enable the primary site's SSH service, but you will need to specify non-default ports so they don't conflict with the secondary site's ports. For example, in your primary site's `gdk.yml`:

```yaml
sshd:
  enabled: true
  listen_port: 2223
  web_listen: localhost:9123 # the default is 9122
```

Or vice versa, you can specify non-default ports for your secondary site.

Note that the Git clone over SSH URL found in project show pages will always display the primary site's Git SSH URL, even if the primary site's SSH service is disabled. There is [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/370377) to improve this behavior.

For more information, see [SSH](ssh.md).

## Geo-specific GDK commands

Use the following commands to keep Geo-enabled GDK installations up to date.

- `make geo-primary-update`, run on the primary GDK node.
- `make geo-secondary-update`, run on any secondary GDK nodes.

## Upgrading to Postgres 12

Upgrading to Postgres 12 is not automated in GDK with Geo. It should be possible to manually accomplish an upgrade, but if you are not generally familiar with the process, it is recommended to set up your GDKs from scratch. The default version is now Postgres 12.

## Troubleshooting

### `postgresql-geo/data` exists but is not empty

If you see this error during setup because you have already run `make geo-setup` once:

```plaintext
initdb: directory "postgresql-geo/data" exists but is not empty
If you want to create a new database system, either remove or empty
the directory "postgresql-geo/data" or run initdb
with an argument other than "postgresql-geo/data".
make: *** [postgresql/geo] Error 1
```

Then you may delete or move that data in order to run `make geo-setup` again.

```shell
mv postgresql-geo/data postgresql-geo/data.backup
```

### GDK update command error on secondaries

You see the following error after running `gdk update` on your local Geo
secondary. It is ok to ignore. Your local Geo secondary does not have or need a
test DB, and this error occurs on the very last step of `gdk update`.

```shell
cd /Users/foo/Developer/gdk-geo/gitlab && \
      bundle exec rake db:migrate db:test:prepare
rake aborted!
ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute DROP DATABASE in a read-only transaction
: DROP DATABASE IF EXISTS "gitlabhq_test"
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `load'
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `<main>'

Caused by:
PG::ReadOnlySqlTransaction: ERROR:  cannot execute DROP DATABASE in a read-only transaction
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `load'
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `<main>'
Tasks: TOP => db:test:load => db:test:purge
(See full trace by running task with --trace)
make: *** [gitlab-update] Error 1
```

## Enabling Docker Registry replication

For information on enabling Docker Registry replication in GDK, see
[Docker Registry replication](geo-docker-registry-replication.md).
