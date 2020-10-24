# GDK configuration

This document describes how you can configure your GDK environment.

## Git configuration

Git has features which are disabled by default, and would be great to enable to
be more effective with Git. Run `rake git:configure` to set the recommendations
for some repositories within the GDK.

To set the configuration globally, run `rake git:configure[true]`. When using
`zsh`, don't forget to escape the square brackets: `rake git:configure\[true\]`.

## GDK configuration

There are many configuration options for GDK. GDK can be configured using either:

- [`gdk.yml`](#gdkyml) configuration file.
- [Loose files](#loose-files-deprecated) (deprecated).

### `gdk.yml`

You can override the GDK's default settings with a `gdk.yml` in the GDK root,
which is the only supported configuration method.

To see available configuration settings, see [`gdk.example.yml`](../gdk.example.yml).

This file contains all possible settings with example values. Note
that these values may not be the default that GDK uses.

If you want to check which settings are in place, you can run `rake dump_config`, which prints
all applied settings in a YAML structure.

#### Run GitLab and GitLab FOSS concurrently

To have multiple GDK instances running concurrently, for example to test GitLab and GitLab FOSS,
initialize each into a separate GDK folder. To run them simultaneously, make sure they don't use
conflicting port numbers.

For example, you can create the following `gdk.yml` in the GitLab FOSS GDK to customise to avoid conflicting port numbers:

```yaml
port: 3001
webpack:
  port: 3809
gitlab_pages:
  port: 3011
```

#### Overwriting configuration files

Any configuration file managed by GDK is overwritten
whenever there are changes in its source (a `.example` or `.erb`
file). When GDK overwrites a configuration file it moves the original file
into the `.backups` subdirectory of your GDK installation.

If you have local changes that you don't want GDK to touch you can
protect individual configuration files. For example:

```yaml
# in gdk.yml
gdk:
  protected_config_files:
  - 'gitaly/*.toml'
```

> Note that `gdk.yml` is not managed by GDK and GDK never overwrites it.

#### Notable settings

Here are a few settings worth mentioning:

| Setting                 | Default            | Description                                                                                |
|------------------------ |--------------------|--------------------------------------------------------------------------------------------|
| `port`                  | `3000`             | Select the port to run GDK on, useful when running multiple GDKs in parallel.              |
| `webpack.port`          | `3808`             | Also useful to configure when running GDKs in parallel. [See below for more webpack options](#webpack-settings). |
| `gitlab_pages.host`     | `127.0.0.1.nip.io` | Specify GitLab Pages hostname. See also the [Pages guide](howto/pages.md#hostname). |
| `gitlab_pages.port`     | `3010`             | Specify on which port GitLab Pages should run. See also the [Pages guide](howto/pages.md#port). |
| `relative_url_root`     | `/`                | When you want to test GitLab being available on a different path than `/`. For example, `/gitlab`. |
| `object_store.enabled`  | `false`            | Set this to `true` to enable Object Storage with MinIO.                                    |
| `registry.enabled`      | `false`            | Set this to `true` to enable container registry.                                           |
| `geo.enabled`           | `false`            | Set this to `true` to enable Geo (for now it just enables `postgresql-geo` and `geo-cursor` services). |

For example, to change the port GDK is accessible on, you can set this in your `gdk.yml`:

```yaml
port: 3001
```

And run the following command to apply the change:

```shell
gdk reconfigure
```

#### GDK settings

There are also a few settings that configure the behavior of GDK itself:

| Setting                           | Default | Description                                                                                      |
|-----------------------------------|---------|--------------------------------------------------------------------------------------------------|
| `gdk.ask_to_restart_after_update` | `true`  | Set this to `false` if you do not wish to be prompted to restart your GDK after an update. |
| `gdk.debug`                       | `false` | Set this to `true` to enable increased output. |
| `gdk.overwrite_changes`           | `false` | When set to `true`, `gdk reconfigure` overwrites files and move the old version to `.backups`.|
| `gdk.protected_config_files`           | `[]` | Contains file names / globs of configuration files GDK should not overwrite. |

##### Experimental GDK settings

Experimental settings may be promoted to stable settings or they may be deprecated.

| Setting | Default | Description |
|---------|---------|-------------|
| `gdk.experimental.quiet` | `false` | Set this to `true` to reduce the level of output when updating the GDK. |
| `gdk.experimental.auto_reconfigure` | `false` | Set this to `true` to automatically run a `gdk reconfigure` after a successful `gdk update`. |

### NGINX settings

| Setting | Default | Description |
|---------|---------|-------------|
| `nginx.enabled` | `false` | Set this to `true` to enable the `nginx` service. |
| `nginx.listen` | `127.0.0.1` | Set this to the IP for NGINX to listen on. |
| `nginx.bin` | `/usr/sbin/nginx` | Set this to the path to your `nginx` binary. |
| `nginx.ssl.certificate` | `localhost.crt` | This maps to [NGINX's `ssl_certificate`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate). |
| `nginx.ssl.key` | `localhost.key` | This maps to [NGINX's `ssl_certificate_key`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate_key). |
| `nginx.http2.enabled` | `false` | Set this to `true` to enable HTTP/2 support. |

See [configuring NGINX](howto/nginx.md) for a comprehensive guide.

### Loose files (deprecated)

Before `gdk.yml` was introduced, GDK could be configured through a
bunch of loose files, where each file sets one setting.

It is still possible to use these loose files, but it's deprecated and
will be removed in the future. A migration path will be provided
when this option is removed.

Below is a table of all the settings that can be set this way:

| Filename                     | Type         | Default                                                                              |
|------------------------------|--------------|--------------------------------------------------------------------------------------|
| `host` / `hostname`          | string or IP | `127.0.0.1`                                                                          |
| `port`                       | number       | `3000`                                                                               |
| `https_enabled`              | boolean      | `false`                                                                              |
| `relative_url_root`          | string       | `/`                                                                                  |
| `webpack_host`               | string or IP | `127.0.0.1`                                                                          |
| `webpack_port`               | number       | `3808`                                                                               |
| `registry_enabled`           | boolean      | `false`                                                                              |
| `registry_port`              | number       | `5000`                                                                               |
| `registry_image`             | string       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v2.9.1-gitlab`   |
| `object_store_enabled`       | boolean      | `false`                                                                              |
| `object_store_port`          | number       | `9000`                                                                               |
| `postgresql_port`            | number       | `5432`                                                                               |
| `postgresql_geo_port`        | number       | `5432`                                                                               |
| `gitlab_pages_port`          | number       | `3010`                                                                               |
| `auto_devops_enabled`        | boolean      | `false`                                                                              |
| `auto_devops_gitlab_port`    | number       | `rand(20000..24999)`                                                                 |
| `auto_devops_registry_port`  | number       | `auto_devops_gitlab_port + 5000`                                                     |
| `google_oauth_client_secret` | ?            | ?                                                                                    |
| `google_oauth_client_id`     | ?            | ?                                                                                    |

### Configuration precedence

GDK uses the following order of precedence when selecting the
configuration method to use:

- `gdk.yml`
- Loose file
- Default value

### Reading the configuration

To print settings from the configuration you can use `gdk config get <setting>`.

More information on the available `gdk` commands is found in
[GDK commands](gdk_commands.md#configuration).

### Implementation detail

Here are some details on how the configuration management is built.

#### GDK::ConfigSettings

This is the base class and the engine behind the configuration
management. It defines a DSL to configure GDK.

Most of the magic happens through the class method
`.method_missing`. The implementation of this method dynamically
defines instance methods for configuration settings.

Below is an example subclass of `GDK::ConfigSettings` to demonstrate
each kind.

```ruby
class ExampleConfig < GDK::ConfigSettings
  foo 'hello'
  bar { rand(1..10) }
  fuz do |f|
    f.buz 1234
  end
end
```

- `foo`: (literal value) This is just a literal value, it can be any
  type (for example, Number, Boolean, String).
- `bar`: (block without argument) This is using a block to set a
  value. It evaluates the Ruby code to dynamically calculate a value.
- `fuz`: (block with argument) When the block takes a single argument,
  it expects you'll be setting child settings.

If you'd dump this configuration with `rake dump_config` you'll get something
like:

```yaml
foo: hello
bar: 5
fuz:
  buz: 1234
```

When you use a block without argument you can also calculate a value
based on another setting. So for example, we'd could replace the `bar`
block with `{ config.fuz.buz + 1000 }` and then the value would be
`2234`.

#### `GDK::Config`

`GDK::Config` is the single source of truth when it comes down to
defaults. In this file, every existing setting is specified and for
each setting a default is provided.

#### Dynamic settings

Some settings in `GDK::Config` are prepended with `__` (double
underscore). These are not supposed to be set in `gdk.yml` and only
act as a intermediate value. They also are not shown by `#dump!`.

### Adding a setting

When you add a new setting:

1. Add it to `lib/gdk/config.rb`.
1. Run `rake gdk.example.yml` to regenerate this file.
1. Commit both files.

## Webpack Settings

### Webpack `gdk.yml` settings

Under the webpack key you can define the following settings with their defaults:

```yaml
webpack:
  host: 127.0.0.1
  port: 3808
  static: false
  vendor_dll: false
```

| Setting | Default | Description |
| --- | ------ | ----- |
| `host` | `127.0.0.1` | The host your webpack development server is running on. Usually no need to change. |
| `port` | `3808` | The port your webpack development server is running on. You should change this if you are running multiple GDKs |
| `static` | `false` | Setting this to `true` replaces the webpack development server with a lightweight Ruby server with. See below for more information |
| `vendor_dll` | `false` | Setting this to `true` moves certain dependencies to a webpack DLL. See below for more information |
| `sourcemaps` | `true` | Setting this to `false` disables source maps. This reduces memory consumption for those who do not need to debug frontend code. |
| `live_reload` | `true` | Setting this to `false` disables hot module replacement when changes are detected. This feature uses sockets and is currently incompatible with SSL, so it is disabled by default when SSL is enabled. |

#### Saving memory on the webpack development server

GDK defaults to memory-intensive settings. GDK uses the webpack development server, which watches
file changes and keeps all the frontend assets in memory. This allows for very fast recompilation.

An alternative is to lower the memory requirements of GDK. This is useful for back-end development
or where GDK is running in lower-memory environments. To lower the memory requirements of GDK:

- Set `webpack.static: true` in your `gdk.yml`. All frontend assets are compiled once when GDK starts
  and again from scratch if any front-end source or dependency file changes. For example, when
  switching branches.
- Set `webpack.vendor_dll: true` in your `gdk.yml`. This mode is an alternate memory saving mode,
  which takes infrequently updated dependencies and combines them into one long-lived bundle that is
  written to disk and does not reside in memory. You may see 200 to 300 MB in memory savings.

This means you pay a high upfront cost of a single memory- and CPU-intenstive compile. However, if
you do not change any frontend files, you just have a lightweight Ruby server running.

If you experience any problems with one of the modes, you can quickly change the settings in your
`gdk.yml` and regenerate the `Procfile`:

```shell
gdk reconfigure
```

### Webpack ENV variables

The GitLab application exposes various configuration options for webpack via
ENV variables. These can be modified to improve performance or enable debugging.

These settings can be configured using [`env.runit`](runit.md#modifying-environment-configuration-for-services).

| Variable | Default | Description |
| ------------- | ------- | ----------- |
| DEV_SERVER_LIVERELOAD | true | Disables live reloading of frontend assets |
| NO_COMPRESSION        | false | Disables compression of assets |
| NO_SOURCEMAPS         | false | Disables generation of source maps (reduces size of `main.chunk.js` by ~50%) |
| WEBPACK_MEMORY_TEST   | false | Output the in-memory heap size upon compilation and exit |
| WEBPACK_CACHE_PATH    | `./tmp/cache` | Path string to temporary dir     |
| WEBPACK_REPORT        | false       | Generates bundle analysis report |
| WEBPACK_VENDOR_DLL    | false       | Reduce webpack-dev-server memory requirements when vendor bundle has been precompiled with `yarn webpack-vendor` |

## ActionCable settings

Under the `action_cable` key you can define the following settings with their defaults:

```yaml
action_cable:
  in_app: true
  worker_pool_size: 4
```

| Setting            | Default | Description |
|--------------------|---------|-------------|
| `in_app`           | `true`  | Set this to `false` to run ActionCable as a separate service. |
| `worker_pool_size` | `4`     | Adjust this to control the number of ActionCable threads. This usually doesn't need to be changed. |

By default, ActionCable runs in-app using the same Puma workers used to serve web requests. This results in memory
savings since we don't need to start another process that boots the whole GitLab Rails app.

When this is set to `false`, a separate Puma process starts to handle ActionCable requests and workhorse is
configured to proxy to this process.
