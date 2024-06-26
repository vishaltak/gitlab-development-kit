# Zoekt

GitLab Enterprise Edition has a [Zoekt](https://github.com/sourcegraph/zoekt)
integration, which you can enable in your development environment.

## Installation

### Enable Zoekt in the GDK

The default version of Zoekt is automatically downloaded into your GDK root under `/zoekt`.
The default version of GitLab Zoekt Indexer is automatically downloaded into your GDK root under `/gitlab-zoekt-indexer`.

To enable the service and run it as part of `gdk start`:

1. Run `gdk config set zoekt.enabled true`.
1. Run `gdk reconfigure`.
1. Run `gdk start` which now starts 4 Zoekt servers:
   - `gitlab-zoekt-indexer` for test.
   - `gitlab-zoekt-indexer` for development.
   - `zoekt-webserver` for test.
   - `zoekt-webserver` for development.

### Configure Zoekt in development

Zoekt must be enabled for each namespace you wish to index. Launch the Rails
console with `gdk rails c`. Given the default ports for Zoekt in GDK and
assuming your local instance has a namespace called `flightjs` (which is a GDK
seed by default), run the following from the Rails console:

```ruby
::Feature.enable(:index_code_with_zoekt)
::Feature.enable(:search_code_with_zoekt)
zoekt_node = ::Search::Zoekt::Node.find_or_create_by!(index_base_url: 'http://127.0.0.1:6080/', search_base_url: 'http://127.0.0.1:6090/', uuid: '00000000-0000-0000-0000-000000000000')
namespace = Namespace.find_by_full_path("flightjs") # Some namespace you want to enable
enabled_namespace = Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
zoekt_node.indices.create!(zoekt_enabled_namespace_id: enabled_namespace.id, namespace_id: namespace.id, state: :ready)
```

Now, if you create a new public project in the `flightjs` namespace or update
any existing public project in this namespace, it is indexed in Zoekt. Code
searches within this project are served by Zoekt.

Group-level searches in `flightjs` are also served by Zoekt. You must
enable [Elasticsearch](elasticsearch.md) to perform group-scoped code searches,
but <https://gitlab.com/gitlab-org/gitlab/-/issues/389750> proposes to change this behavior.

### Switch to a different version of Zoekt

The default Zoekt version is defined in [`lib/gdk/config.rb`](../../lib/gdk/config.rb).

You can change this by setting `repo` and/or `version`:

```shell
   gdk config set zoekt.repo https://github.com/MyFork/zoekt.git
   gdk config set zoekt.version v1.2.3
```

Here, `repo` is any valid repository URL that can be cloned, and
`version` is any valid ref that can be checked out.

### Switch to a different version of GitLab Zoekt Indexer

The default GitLab Zoekt Indexer version is defined in [`lib/gdk/config.rb`](../../lib/gdk/config.rb).

To change this, set `indexer_version`:

```shell
   gdk config set zoekt.indexer_version v1.2.3
```

`indexer_version` is any valid ref that can be checked out.

## Troubleshooting

### No preset version installed for command go

If you get this error during installation, execute the provided command
to install the correct version of Go:

```plaintext
No preset version installed for command go
Please install a version by running one of the following:
```

We cannot use the same Go version we use for other tools because the supported
version is controlled by Zoekt.
