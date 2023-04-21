# pgvector

GitLab Enterprise Edition has an optional embedding database that uses the
pgvector PostgreSQL extension. You can enable building and installing this
extension for the PostgreSQL used in your development environment.

## Installation

### Enable pgvector in the GDK

The default version of pgvector is automatically downloaded into your GDK root
under `/pgvector`.

To enable building and installing it into PostgreSQL:

1. Run `gdk config set pgvector.enabled true`.
1. Run `gdk reconfigure`.

### Switch to a different version of pgvector

The default pgvector version is defined in
[`lib/gdk/config.rb`](../../lib/gdk/config.rb).

You can change this by setting `repo` and/or `version`:

```yaml
pgvector:
  enabled: true
  repo: https://github.com/MyFork/pgvector.git
  version: v0.4.2
```

Here, `repo` is any valid repository URL that can be cloned, and `version` is
any valid ref that can be checked out.
