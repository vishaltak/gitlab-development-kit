# Zoekt

GitLab Enterprise Edition has a [Zoekt](https://github.com/sourcegraph/zoekt)
integration. In this document we explain how to set this up in your development
environment.

## Installation

### Enable Zoekt in the GDK

The default version of Zoekt is automatically downloaded into your GDK root under `/zoekt`.

To enable the service and make it run as part of `gdk start`:

1. Add these lines to your [`gdk.yml`](../configuration.md):

   ```yaml
   zoekt:
     enabled: true
   ```

1. Run `gdk reconfigure`.

1. Run `gdk start` which now starts 4 Zoekt servers:

1. `zoekt-dynamic-indexserver` for test
1. `zoekt-dynamic-indexserver` for development
1. `zoekt-webserver` for test
1. `zoekt-webserver` for development

### Configure Zoekt in development

Zoekt must be enabled for each namespace you wish to index. Given the default
ports for Zoekt in GDK and assuming your local instance has a namespace called
`flightjs` (which is a GDK seed by default) then, from the Rails console, run:

```ruby
::Feature.enable(:index_code_with_zoekt)
::Feature.enable(:search_code_with_zoekt)
zoekt_shard = ::Zoekt::Shard.find_or_create_by!(index_base_url: 'http://127.0.0.1:6080/', search_base_url: 'http://127.0.0.1:6090/')
namespace = Namespace.find_by_full_path("flightjs") # Some namespace you want to enable
::Zoekt::IndexedNamespace.find_or_create_by!(shard: zoekt_shard, namespace: namespace.root_ancestor)
```

Now if you create a new public project in the `flightjs` namespace, or update
any existing public project in this namespace, it will become indexed in Zoekt
and code searches within this project will be served by Zoekt.

Group level searches in `flightjs` will also be served by Zoekt, but until
<https://gitlab.com/gitlab-org/gitlab/-/issues/389750> is fixed you won't be
able to do group scoped code searches unless you also
[enable Elasticsearch](elasticsearch.md).

## Troubleshooting

### No preset version installed for command go

If you get the following error during installation then execute the supplied
command to install the correct version of Go:

```plaintext
No preset version installed for command go
Please install a version by running one of the following:
```

We cannot use the same Golang version we use for other tools as the supported
version is controlled by Zoekt.

## Switching to a different version of Zoekt

The default Zoekt version is defined in [`lib/gdk/config.rb`](../../lib/gdk/config.rb).

You can change this by setting `repo` and/or `version`:

   ```yaml
   zoekt:
     enabled: true
     repo: https://github.com/MyFork/zoekt.git
     version: v1.2.3
   ```

Here `repo` is any valid repository URL that can be cloned and `version` is any
valid ref that can be checked out.
