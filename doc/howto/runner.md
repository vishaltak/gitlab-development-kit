# Using GitLab Runner with GDK

Most features of [GitLab CI/CD](http://docs.gitlab.com/ee/ci/) need a
[runner](http://docs.gitlab.com/ee/ci/runners/README.html) to be registered with
the GitLab installation. This how-to takes you through the necessary steps to
do so when GitLab is running under GDK.

Before setting up a runner, you must have [set up the GDK](../index.md) for your workstation.

You can set up:

- A runner to run directly on your workstation
- A runner in Docker.

The GDK supports managing the runner configuration file and the process itself, either with a native binary
or within a Docker container. Running jobs inside a Docker executor is supported in both cases; you can use a native
binary to run jobs inside a Docker container.

We outline the steps for setting up each of these separately.

- [Simple configuration](#simple-configuration)
- [Docker configuration](#docker-configuration) (recommended)

NOTE:
In the configuration examples, `runner` should not be confused with [`gitlab_runner`](gitlab_docs.md).

## Simple configuration

If you intend to just use the `shell` executor (fine for simple jobs), you can use the GDK with its default settings.
Builds run directly on the host computer. If you choose this configuration, don't use random `.gitlab-ci.yml`
files from the internet unless you understand them fully as this could be a security risk. If you need a basic pipeline,
see an [example configuration from our documentation](https://docs.gitlab.com/ee/ci/environments/#configure-manual-deployments) that
you can use.

### Download GitLab Runner

Before you register a runner in your GDK, you first must have a runner binary either:

- Pre-built. To use a pre-built binary, follow [the runner installation instructions](https://docs.gitlab.com/runner/install/#binaries)
  for your specific operation system. Avoid following the instructions in the **Containers** section because it's simpler
  to let the GDK manage the runner process.
- Compiled from source. To build from source, follow [the runner development instructions](https://docs.gitlab.com/runner/development/).
  See the official [GitLab Runner repository](https://gitlab.com/gitlab-org/gitlab-runner).

By default, GDK expects the runner binary to be at `/usr/local/bin/gitlab-runner`. To specify a custom `gitlab-runner`
binary location, add the following to `gdk.yml`:

```yaml
runner:
  bin: <path_to_gitlab_runner_binary>/gitlab-runner-darwin-amd64
```

### Set up a local runner

With a local runner installed, run `gitlab-runner register --run-untagged --config <path-to-gdk>/gitlab-runner-config.toml`
(as your normal user), and follow the prompts:

- **coordinator URL**: Use `http://localhost:3000/`, or `http://<custom_IP_address>:3000/` if you customized your IP
  address.
- **token**: Value of **Registration token** copied from `<coordinator-url>/admin/runners`.
- **description** (optional): A description of the runner. Defaults to the hostname of the machine.
- **tags** (optional): Comma-separated tags. Jobs can be set up to use only runners with specific tags.
- **executor**: Because we are running directly on the host computer, choose `shell`.

The runner writes its configuration file to `gitlab-runner-config.toml`, which is in GDK's `.gitignore` file.

To ensure the runner token persists between subsequent runs of `gdk reconfigure`, add the token (from `gitlab-runner-config.toml`,
not the **Registration token**), to your `gdk.yml` file and set `executor` to `shell`:

```yaml
runner:
  enabled: true
  executor: shell
  token: <runner-token>
```

Finally, run `gdk update` to rebuild your `Procfile`. This allows you to manage the runner along with your other GDK processes.

Alternately, run `gitlab-runner --log-level debug run --config <path-to-gdk>/gitlab-runner-config.toml`
to get a long-lived runner process, using the configuration you created in the
last step. It stays in the foreground, outputting logs as it executes
builds, so run it in its own terminal session.

The **Runners** page (`/admin/runners`) now lists the runners. Create a project in the GitLab UI and add a
[`.gitlab-ci.yml`](https://docs.gitlab.com/ee/ci/examples/) file,
or clone an [example project](https://gitlab.com/groups/gitlab-examples), and
watch as the runner processes the builds just as it would on a "real" install!

## Docker configuration

Instead of running GitLab Runner locally on your workstation, you can run it using Docker instead.

### Set up a runner

To [register a runner](https://docs.gitlab.com/runner/register/index.html#docker) in
your GDK, you can run the `gitlab/gitlab-runner` Docker image. You must
ensure that the runner saves the configuration to a file that is
accessible to the host after the registration is complete. Here we use
`/tmp/gitlab-runner` as an example:

```shell
mkdir /tmp/gitlab-runner
docker run --rm -it -v /tmp/gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner register --run-untagged
```

(optional) If you have [SSL enabled with NGINX](nginx.md), a
Docker-based runner needs access to your self-signed certificate
(for example, `gdk.test.pem`). Suppose your certificate is in
`/Users/example/gdk/gdk.test.pem`, you can register your runner in this
way:

```shell
mkdir /tmp/gitlab-runner
cp /Users/example/gdk/gdk.test.pem /tmp/gitlab-runner
docker run --rm -it --env=SSL_CERT_FILE=/etc/gitlab-runner/gdk.test.pem -v /tmp/gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner register --run-untagged
```

The following prompts appear:

- **coordinator URL**: Use `http://localhost:3000/`, or `http://<custom_IP_address>:3000/` if you customized your IP
  address.
- **token**: Value of **Registration token** copied from `<coordinator-url>/admin/runners`.
- **description** (optional): A description of the runner.
- **tags** (optional): Comma-separated tags. Jobs can be set up to use only runners with specific tags.
- **executor**: Because we are running our runner in Docker, choose `docker`.
- **Docker image**

Using runners in Docker allows you to set up a clean environment for your builds
each time. It is also safer than running directly on your computer, as the
runner does not have direct access to your computer.

Once the registration is complete, find the token in `/tmp/gitlab-runner/config.toml`.
For example:

```shell
# grep token /tmp/gitlab-runner/config.toml
token = "<runner-token>"
```

The GDK manages a runner in a Docker container for you, but it needs
this token in your `gdk.yml` file. Edit the `gdk.yml` to use this value
and set `install_mode` and `executor` to `docker`:

```yaml
runner:
  enabled: true
  install_mode: docker
  executor: docker
  token: <runner-token>
```

Running `gdk reconfigure` creates `<path-to-gdk>/gitlab-runner-config.toml`.

For SSL users, the GDK configures the Docker runner with
[`tls_verify`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersdocker-section)
set to `false`, so SSL verification is disabled by
default.

### Set up Docker and GDK

Ensure you have Docker installed, then we must set up GitLab to bind to an IP on your machine
instead of `127.0.0.1`. Without this step, builds fail with a `connection refused` error.

The easiest and most universal way to set this up is by using an internal, dummy interface that can
be used by both the host and the Docker container.

1. [Create a loopback interface](local_network.md#create-loopback-interface) for a new private network.
1. In the GitLab Runner configuration (for example, `~/.gitlab-runner/config.toml`), set the coordinator
   URL with an IP on this private network:

  ```toml
  url = "http://172.16.123.1:3000/"
  ```

This can also be combined with a custom hostname by following these
[instructions for setting up `gdk.test`](local_network.md) but using the `172.16.123.1`
instead of `127.0.0.1`. Then set up your runner to resolve the hostname by adding `runner.extra_hosts`
to your `gdk.yml`. For example, for `gdk.test`:

  ```yaml
  runner:
    extra_hosts: ["gdk.test:172.16.123.1"]
  ```

If creating a loopback interface proves troublesome, another method is to use `extra_hosts`
to alias your GDK hostname to your `host.docker.internal` IP address.

You can find this IP by doing a DNS lookup:

```shell
$ docker run --rm -ti tutum/dnsutils dig +short host.docker.internal
192.168.65.2
```

Then add it to your `extra_hosts` configuration:

```yaml
runner:
  extra_hosts: ["gdk.test:192.168.65.2"]
```

### Alternative method for Linux

An alternative to creating the dummy interface described above is to:

1. Add the following to your `gdk.yml`

    ```yaml
    runner:
      network_mode_host: true
    ```

1. Run `gdk reconfigure`

This will add `network_mode = host` to the `gitlab-runner-config.toml` file:

```toml
[[runners]]
  [runners.docker]
    ...
    network_mode = "host"
```

Note that this method:

- [Only works with Linux hosts](https://docs.docker.com/network/host/).
- Exposes your local network stack to the Docker container, which may be a security issue. Use
  it only to run jobs on projects that you trust.
- Won't work with Docker containers running in Kubernetes because Kubernetes uses its own
  internal network stack.

### Put it all together

At the end of all these steps, your `gdk.yml` might look something like:

```yaml
hostname: gdk.test
runner:
  enabled: true
  executor: docker
  install_mode: docker
  token: <runner-token>
  extra_hosts: ["gdk.test:172.16.123.1"]
```

1. Be sure to replace `<runner-token>` with the value inside the generated `/tmp/gitlab-runner/config.toml`.
1. Run `gdk reconfigure`.
1. This generates `gitlab-runner-config.toml` in your GDK directory and enable the runner inside a Docker container.
1. `gdk start runner` starts the runner.
1. Check `docker ps` to ensure that the runner is running.
1. `gdk stop runner` stops the runner.

Note that any changes in `gitlab-runner-config.toml` are lost after
every `gdk reconfigure`. If you need support for other configuration
settings, file a [GDK issue](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues) or
use a separate runner and configuration file for now.

### Troubleshooting tips

- In the GitLab Web interface, check `/admin/runners` to ensure that
  your runner has contacted the server. If the runner is there but
  offline, this suggests the runner registered successfully but is now
  unable to contact the server via a `POST /api/v4/jobs/request` request.
- Run `gdk tail runner` to look for errors.
- Check that the runner can access the hostname specified in `gitlab-runner-config.toml`.
- Select `Edit` on the desired runner and make sure the `Run untagged jobs` is unchecked. Runners
  that have been registered with a tag may ignore jobs that have no tags.
- Run `tail -f gitlab/log/api_json.log | grep jobs` to see if the runner is attempting to request CI jobs.
