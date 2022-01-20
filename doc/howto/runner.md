# Using GitLab Runner with GDK

Most features of [GitLab CI/CD](http://docs.gitlab.com/ee/ci/) need a
[Runner](http://docs.gitlab.com/ee/ci/runners/README.html) to be registered with
the GitLab installation. This how-to takes you through the necessary steps to
do so when GitLab is running under GDK.

Before setting up Runner, you must have [set up the GDK](../index.md) for your workstation.

You can set up:

- A runner to run directly on your workstation
- A runner in Docker.

The GDK supports managing the runner configuration file and the process itself, either with a native binary
or within a Docker container. Running jobs inside a Docker executor is supported in both cases; you can use a native
binary to run jobs inside a Docker container.

## Download GitLab Runner

To register a runner in your GDK, you first must use a runner binary either:

- Pre-built. To use a pre-built binary, follow [the runner installation instructions](https://docs.gitlab.com/runner/install/#binaries)
  for your specific operation system. Avoid following the instructions in the **Containers** section because it's simpler
  to let the GDK manage the runner process.
- Compiled from source. To build from source, follow [the runner development instructions](https://docs.gitlab.com/runner/development/).
  See the official [GitLab Runner repository](https://gitlab.com/gitlab-org/gitlab-runner).

To specify a custom `gitlab-runner` binary, add the following to `gdk.yml`:

```yaml
runner:
  bin: <path_to_gitlab_runner_binary>/gitlab-runner-darwin-amd64
```

NOTE:
`runner` should not be confused with [`gitlab_runner`](gitlab_docs.md).

## Setting up a Runner

Run `gitlab-runner register --run-untagged --config <path-to-gdk>/gitlab-runner-config.toml` (as your normal user),
and follow the prompts. Use:

- **coordinator URL**

  Use either:

  - `http://localhost:3000/`
  - `http://<custom_IP_address>:3000/`, if you customized your IP address.

- **token**

  `Registration token` (copied from `<coordinator-url>/admin/runners`)

- **description** (optional)

  A description of the Runner. Defaults to the hostname of the machine.

- **tags** (optional)

  Comma-separated tags. Jobs can be set up to use only Runners with specific tags.

- **executor**

  Choose `shell` if you want builds to run directly on the host computer.
  Choose `docker` if you want builds to run inside a Docker container. Follow the
  [Docker configuration below](#docker-configuration-optional) if you choose this option.

The Runner writes its configuration file to `gitlab-runner-config.toml`,
which is in GDK's `.gitignore` file.

To ensure the Runner token persists between subsequent runs of `gdk reconfigure`, add
the token to your `gdk.yml` file:

```yaml
runner:
  enabled: true
  token: <runner-token>
```

Finally, rebuild your `Procfile` with `gdk update` or un-comment
the line that starts with `runner:`. This allows you to manage the runner along with
your other GDK processes.

You can run the `register` command multiple times to set up additional Runners -
fuller documentation on the different types of executor and their requirements
can be found [here](https://docs.gitlab.com/runner/executors/).
Each `register` invocation adds a section to the configuration file, so make
sure you're referencing the same one each time.

Alternately, run `gitlab-runner --log-level debug run --config <path-to-gdk>/gitlab-runner-config.toml`
to get a long-lived Runner process, using the configuration you created in the
last step. It stays in the foreground, outputting logs as it executes
builds, so run it in its own terminal session.

The Runners pane in the administration panel now lists the Runners. Create a
project in the GitLab web interface and add a
[`.gitlab-ci.yml`](https://docs.gitlab.com/ee/ci/examples/) file,
or clone an [example project](https://gitlab.com/groups/gitlab-examples), and
watch as the Runner processes the builds just as it would on a "real" install!

## Run a build

If you intend to just use the "shell" executor (fine for simple jobs), you're done!
Builds run directly on the host computer. If you choose this configuration, don't use random `.gitlab-ci.yml`
files from the internet unless you understand them fully as this could be a security risk. If you need a basic pipeline,
see an [example configuration from our documentation](https://docs.gitlab.com/ee/ci/environments/#configuring-manual-deployments) that
you can use.

## Docker configuration (optional)

Using runners in Docker allows you to set up a clean environment for your builds
each time. It is also safer than running directly on your computer, as the
runner does not have direct access to your computer.

You can have GDK manage a Docker container for you by setting `install_mode: docker`.

```yaml
runner:
  enabled: true
  install_mode: docker
```

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
  install_mode: docker
  extra_hosts: ["gdk.test:172.16.123.1"]
  token: <runner-token>
```

1. Be sure to replace `<runner-token>` with the value inside `gitlab-runner-config.toml` after registering.
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
