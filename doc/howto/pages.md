# Pages

## Port

GDK features an HTTP-only GitLab Pages daemon on port `3010`.
Port number can be customized editing `gdk.yml` as explained in
[GDK configuration](../configuration.md#gdkyml).

## Hostname

In order to handle wildcard hostnames, pages integration relies on
[nip.io](https://nip.io) and will not work on a disconnected system.
This is the preferred configuration and the default value for the
GitLab Pages hostname will be `127.0.0.1.nip.io`.

To use a custom hostname, you will need to add an entry to your
`/etc/hosts` file. For example, if you'd like to use GitLab Pages with
the hostname `pages.localhost`:

```plaintext
127.0.0.1 pages.localhost
```

However, to load your Pages domains, you will need to add an entry to
the `/etc/hosts` files per domain you want to acces. For example, to
access `root.pages.localhost`, add the following to `/etc/hosts`

```plaintext
127.0.0.1 root.pages.localhost
```

That is because `/etc/hosts` does not support wildcard hostnames.
An alternative is to use [`dnsmasq`](https://wiki.debian.org/dnsmasq)
to handle wildcard hostnames.
