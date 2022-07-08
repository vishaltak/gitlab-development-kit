# LDAP

You can run an OpenLDAP daemon inside the GDK if you want to work on the
GitLab LDAP integration.

## Installation

### Enable OpenLDAP in the GDK

1. Add the following to your `<gdk-root>/gdk.yml` file:

   ```yaml
   openldap:
     enabled: true
   ```

1. Run `gdk reconfigure` to configure the `gitlab-openldap` service.

1. Run `gdk restart` to restart the modified services.

1. On the login screen, there will now be two tabs: `LDAP` and
`LDAP-alt`. See the following table for username and password
combinations that can be used. The users (example: `john`) with
`dc=example` in the `DN` column can sign in on the `LDAP` tab, while
users with `dc=example=alt` (example: `bob`) can sign in on the
`LDAP-alt` tab.

### LDAP users

The following users are added to the LDAP server:

| uid      | Password | DN                                          | Last     |
| -------- | -------- | -------                                     | ----     |
| john     | password | `uid=john,ou=people,dc=example,dc=com`      |          |
| john0    | password | `uid=john0,ou=people,dc=example,dc=com`     | john9999 |
| mary     | password | `uid=mary,ou=people,dc=example,dc=com`      |          |
| mary0    | password | `uid=mary0,ou=people,dc=example,dc=com`     | mary9999 |
| bob      | password | `uid=bob,ou=people,dc=example-alt,dc=com`   |          |
| alice    | password | `uid=alice,ou=people,dc=example-alt,dc=com` |          |

### LDAP groups

For testing of GitLab Enterprise Edition the following groups are created:

| cn            | DN                                              | Members | Last          |
| -------       | --------                                        | ------- | ----          |
| group1        | `cn=group1,ou=groups,dc=example,dc=com`         | 2       |               |
| group2        | `cn=group2,ou=groups,dc=example,dc=com`         | 1       |               |
| group-a       | `cn=group-a,ou=groups,dc=example-alt,dc=com`    | 2       |               |
| group-b       | `cn=group-b,ou=groups,dc=example-alt,dc=com`    | 1       |               |
| group-10-0    | `cn=group-10-0,ou=groups,dc=example,dc=com`     | 10      | group-10-1000 |
| group-100-0   | `cn=group-100-0,ou=groups,dc=example,dc=com`    | 100     | group-100-100 |
| group-1000-0  | `cn=group-1000-0,ou=groups,dc=example,dc=com`   | 1,000   | group-1000-10 |
| group-10000-0 | `cn=group-10000-0,ou=groups,dc=example,dc=com`  | 10,000  | group-10000-1 |

By default, only `group1`, `group2`, `group-a`, and `group-b` are created. If you wish
to create more users and groups, run:

```shell
cd <gdk-directory>/gitlab-openldap
make large
```

## Manual setup instructions

```shell
cd <gdk-directory>/gitlab-openldap
make # compile openldap and bootstrap an LDAP server to run out of slapd.d
```

We can also simulate a large instance with many users and groups:

```shell
make large
```

Then run the daemon:

```shell
./run-slapd # stays attached in the current terminal
```

### Configuring GitLab

In `<gdk-directory>/gitlab/config/gitlab.yml` under `production:` and `ldap:`, change the following keys to the values
given below (see [defaults](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example#L550-769)):

```yaml
  enabled: true
  servers:
    main:
      # ...
      host: 127.0.0.1
      port: 3890  # on macOS: 3891
      uid: 'uid'
      # ...
      base: 'dc=example,dc=com'
      group_base: 'ou=groups,dc=example,dc=com'  # Insert this
```

In GitLab EE, an alternative database can optionally be added as follows:

```yaml
    main:
      # ...
    alt:
      label: LDAP-alt
      host: 127.0.0.1
      port: 3891  # on macOS: 3892
      uid: 'uid'
      encryption: 'plain' # "tls" or "ssl" or "plain"
      base: 'dc=example-alt,dc=com'
      user_filter: ''
      group_base: 'ou=groups,dc=example-alt,dc=com'
      admin_group: ''
```

### Repopulate the database

```shell
cd <gdk-directory>/gitlab-openldap
make clean default
```

### Optional: disable anonymous binding

The above config does not use a bind user, to keep it as simple as possible.
If you want to disable anonymous binding and require authentication:

1. Run the following command:

   ```shell
   make disable_bind_anon
   ```

1. Update `gitlab.yml` also with the following:

   ```yaml
   ldap:
     enabled: true
     servers:
       main:
         # ...
         bind_dn: 'cn=admin,dc=example,dc=com'
         password: 'password'
         #...
   ```

## Debugging tips

The following commands should help validate GitLab and OpenLDAP are
configured properly. Also see the [LDAP Troubleshooting documentation](https://docs.gitlab.com/ee/administration/auth/ldap/ldap-troubleshooting.html).

### Rake task

In the `gitlab` directory, run:

```shell
bundle exec rake gitlab:ldap:check
```

You should see two sets of LDAP configurations: one for the domain
component (DC) `example` and one for `example-alt`:

```plaintext
Checking LDAP ...

LDAP: ... Server: ldapmain
LDAP authentication... Anonymous. No `bind_dn` or `password` configured
LDAP users with access to your GitLab server (only showing the first 100 results)
        DN: uid=john,ou=people,dc=example,dc=com         uid: john
        DN: uid=mary,ou=people,dc=example,dc=com         uid: Mary
Server: ldapalt
LDAP authentication... Anonymous. No `bind_dn` or `password` configured
LDAP users with access to your GitLab server (only showing the first 100 results)
        DN: uid=alice,ou=people,dc=example-alt,dc=com    uid: alice
        DN: uid=bob,ou=people,dc=example-alt,dc=com      uid: bob

Checking LDAP ... Finished
```

### ldapsearch

To validate the OpenLDAP server is running and to see what users are available:

```shell
ldapsearch -x -b "dc=example,dc=com" -H "ldap://127.0.0.1:3890"
ldapsearch -x -b "dc=example-alt,dc=com" -H "ldap://127.0.0.1:3890"
```
