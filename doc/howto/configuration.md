# Configuration

This document describes ways how you can configure you GDK environment.

## Custom ports

You may want to customize the ports used by the services, so they can
coexist and be accessible when running multiple GDKs at the same time.

This may also be necessary when simulating some HA behavior or to run Geo.

Most of the time you want to use just the UNIX sockets, if possible,
but there are situations where sockets are not supported (for example
when using some Java-based IDEs).

### List of port files (deprecated)

Below is a list of all existing port configuration files and the
service they are related to:

| Port filename         | Service name                                  |
| --------------------- | --------------------------------------------- |
| `port`                | puma/unicorn (rails)                          |
| `webpack_port`        | webpack-dev-server                            |
| `postgresql_port`     | main postgresql server                        |
| `postgresql_geo_port` | postgresql server for tracking database (Geo) |
| `registry_port`       | docker registry server                        |
| `gitlab_pages_port`   | gitlab-pages port                             |

### gdk.yml

Configuring GitLab via individual files has become unwieldy, and we are
trying to improve this by [consolidating all configuration inside
`gdk.yml`](https://gitlab.com/gitlab-org/gitlab-development-kit/issues/413).

Right now only the `Procfile` is rendered from variables inside
`gdk.yml`. `Procfile` is built from a templated `Procfile.erb`, which
obtains its configuration from `gdk.yml`. See `gdk.example.yml` as a
template for this file.

### Customizing Jaeger ports

To run multiple instances of the GDK, you will have to configure Jaeger
so that multiple processes can run simultaneously. Jaeger listens on four
different ports:

1. `health_check_http_port`
1. `jaeger_binary_port`
1. `jaeger_compact_port`
1. `zipkin_compact_port`

Be sure to configure these ports for different instances.

#### Virtual loopback interfaces

You can save some port assignments by using virtual loopback interfaces
(e.g. 127.0.0.1, 127.0.0.2, etc.) by changing the
`tracer.jaeger.processor.host` variable. For example, on MacOS, you can
create a loopback interface this way:

```
sudo ifconfig lo0 alias 127.0.0.2
```

Then you can save a few ports by changing your `gdk.yml`:

```diff
diff --git a/gdk.yml b/gdk.yml
index c1d6be1..23e55fe 100644
--- a/gdk.yml
+++ b/gdk.yml
@@ -18,7 +18,7 @@ gitaly:
 gitlab_pages:
   enabled: true
   port: 3034
-hostname: localhost
+hostname: 127.0.0.2
 https:
   enabled: true
 nginx:
@@ -63,9 +63,8 @@ tracer:
   jaeger:
     enabled: true
     version: 1.10.1
-    health_check_http_port: 14269
+    health_check_http_port: 14270
     processor:
       jaeger_binary_port: 6832
       jaeger_compact_port: 6831
       zipkin_compact_port: 5775
```

### Using custom ports

To configure a custom port, create the corresponding port file with
just the port as the content, e.g.:

```sh
echo 3807 > webpack_port
```

## Makefile variables

This GitLab Development Kit tries to automatically adapt to your
environment. But in some cases, you still might want to override the
defaults.

To override the default variables used in [`Makefile`](../../Makefile),
you can create a file called `env.mk` at the root of your gdk. In this
file you can assign variables to override the defaults. The possible
variable assignment is:

- `postgres_bin_dir`: GDK automatically detects the directory of the
  PostgreSQL executables, but if you want to override that (e.g. to
  use a different version), use this variable.

- `jaeger_server_enabled`: By default, the GDK will launch an instance of
  the [Jaeger distributed tracing all-in-one
  server](http://localhost:16686/search). If you are running multiple
  copies of GDK, you should set `jaeger_server_enabled=false` in all but
  one GDK instance, and have traces get send to a single instance.

If you change these files, make sure to call `gdk reconfigure` to ensure
they are respected (e.g. that Jaeger is disabled).

### Example

Here an example what `env.mk` might look like:

```makefile
postgres_bin_dir := /path/to/your/preferred/postgres/bin
```
