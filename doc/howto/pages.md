# Pages

This page contains information about developing GitLab Pages inside the GDK. This method allows you test GitLab Pages from deployment to visiting your static site.

If you would like to develop Pages *outside* of the GDK, see [Getting started with development](https://gitlab.com/gitlab-org/gitlab-pages/-/blob/main/doc/development.md) in the `gitlab-pages` repository.

## Port

GDK features an HTTP-only GitLab Pages daemon on port `3010`.
Port number can be customized by editing `gdk.yml` as explained in
[GDK configuration](../configuration.md#gdkyml).

## Hostname

In order to handle wildcard hostnames, pages integration relies on
[nip.io](https://nip.io) and does not work on a disconnected system.
This is the preferred configuration and the default value for the
GitLab Pages hostname is `127.0.0.1.nip.io`.

You can configure a custom host name. For example, to set up `pages.gdk.test`:

1. Set up the [`gdk.test` hostname](../index.md#set-up-gdktest-hostname).
1. Add the following to `gdk.yml`:

   ```yaml
   gitlab_pages:
     host: pages.gdk.test
   ```

1. Also add `pages.gdk.test` as a hostname. For example, add the following to `/etc/hosts`:

   ```plaintext
   127.0.0.1 pages.gdk.test
   ```

However, to load your Pages domains, you must add an entry to the `/etc/hosts` file for
each domain you want to access. For example, to access `root.pages.gdk.test`, add the
following to `/etc/hosts`:

```plaintext
127.0.0.1 root.pages.gdk.test
```

That is because `/etc/hosts` does not support wildcard hostnames.
An alternative is to use [`dnsmasq`](https://wiki.debian.org/dnsmasq)
to handle wildcard hostnames.
