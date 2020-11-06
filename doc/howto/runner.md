# Using GitLab Runner with GDK

Most features of [GitLab CI/CD](http://docs.gitlab.com/ee/ci/) need a
[Runner](http://docs.gitlab.com/ee/ci/runners/README.html) to be registered with
the GitLab installation. This HOWTO will take you through the necessary steps to
do so when GitLab is running under GDK.

## Set up GitLab

Start by [setting up the GDK](../../index.md) for your workstation.

In some configurations, GitLab Runner needs access to GitLab from inside a
Docker container, or even another machine, which isn't supported in the default
configuration.

### Simple configuration

If you intend to just use the "shell" executor (fine for very
simple jobs), you can use GDK with its default settings and skip the Advanced
configuration below. If GDK is already running, you'll need to restart it after making
these changes.

With GDK running:

1. Navigate to `http://localhost:3000/admin/runners` (log in as root)
1. Make note of the `Registration token`.

### Advanced configuration

Ensure you have Docker installed, then set up GitLab to bind to all
IPs on your machine by following [these instructions](local_network.md).
Without this step, builds will fail with a 'connection refused' error.

The configured `hostname` needs to be set to an IP address that
*actually exists on the computer*.

1. Run `ipconfig` (Windows), `ifconfig` (Mac, BSD) or `ip addr show` (Linux) to find
   your machine's network IP address. The IP address to use depends on your network,
   and may change from time to time (via DHCP). An address like `10.x.x.x`,
   `172.16.x.x`, or `192.168.x.x` is normally correct.

   **Note**: If you are comfortable configuring your network, set a static IP for your
   machine so it never changes.

1. In your `gdk.yml` add:

   ```yaml
   hostname: <IP address from previous step>
   ```

1. Reconfigure and restart GDK:

   ```shell
   gdk reconfigure
   gdk restart
   ```

Navigate to `http://<IP address>:3000/gitlab-org/gitlab-test`.
If the URL doesn't work, repeat the last step and pick a different IP.

Once there, ensure that the HTTP clone URL is `http://<ip>:3000/gitlab-org/gitlab-test.git`.
If it points to `localhost` instead, `gitlab/config/gitlab.yml` is incorrect.

Finally, navigate to `http://<ip>:3000/admin/runners` (log in as root) and make
a note of the `Registration token`.

## Download GitLab Runner

### Simple configuration

Runner can be installed using a pre-build binary or from source.

#### Install pre-built binary

Unless you want to make changes to the Runner, it's easiest to install a binary
package. Follow the
[installation instructions](https://docs.gitlab.com/runner/install/)
for your operating system
([Linux](https://docs.gitlab.com/runner/install/linux-repository.html),
[OSX](https://docs.gitlab.com/runner/install/osx.html),
[Windows](https://docs.gitlab.com/runner/install/windows.html)).

#### Build from source

To build from source, you'll need to set up a development environment manually -
GDK doesn't manage it for you. The official GitLab Runner repository is
[here](https://gitlab.com/gitlab-org/gitlab-runner); just follow
[the development instructions](https://docs.gitlab.com/runner/development/).

To specify a custom `gitlab-runner` binary, add the following to `gdk.yml`:

```yaml
runner:
  bin: <path_to_gitlab_runner_binary>/gitlab-runner-darwin-amd64
```

### Advanced configuration

If you followed the advanced configuration and want to install the runner as a Docker service,
follow the steps described in <https://docs.gitlab.com/runner/install/docker.html#docker-image-installation>.

## Setting up the Runner

### Simple configuration

Run `gitlab-runner register --run-untagged --config <path-to-gdk>/gitlab-runner-config.toml`
(as your normal user), and follow the prompts. Use:

- **coordinator URL**

  Use either:

  - `http://localhost:3000/`
  - `http://<custom_IP_address>:3000/`, if you customized your IP address using
    [Advanced Configuration](#advanced-configuration).

- **token**

  `Registration token` (copied from `admin/runners`)

- **description** (optional)

  A description of the Runner. Defaults to the hostname of the machine.

- **tags** (optional)

  Comma-separated tags. Jobs can be set up to use only Runners with specific tags.

The Runner will write its configuration file to `gitlab-runner-config.toml`,
which is in GDK's `.gitignore` file.

To ensure the Runner token persists between subsequent runs of `gdk reconfigure`, add
the token to your `gdk.yml` file:

```yaml
runner:
  enabled: true
  token: <runner-token>
```

If Docker is installed and you followed the special setup instructions above,
choose `docker` as the executor. Otherwise, choose `shell` - but remember that
builds will then be run directly on the host computer! Don't use random
`.gitlab-ci.yml` files from the Internet unless you understand them fully, it
could be a security risk.

You can run the `register` command multiple times to set up additional Runners -
fuller documentation on the different types of executor and their requirements
can be found [here](https://docs.gitlab.com/runner/executors/).
Each `register` invocation adds a section to the configuration file, so make
sure you're referencing the same one each time.

Finally, rebuild your `Procfile` with `rm Procfile; make Procfile` or un-comment
the line that starts with `runner:`. This will allow you to manage it along with
your other GDK processes.

Alternately, run `gitlab-runner --log-level debug run --config <path-to-gdk>/gitlab-runner-config.toml`
to get a long-lived Runner process, using the configuration you created in the
last step. It will stay in the foreground, outputting logs as it executes
builds, so run it in its own terminal session.

The Runners pane in the administration panel will now list the Runners. Create a
project in the GitLab web interface and add a
[`.gitlab-ci.yml`](https://docs.gitlab.com/ee/ci/examples/) file,
or clone an [example project](https://gitlab.com/groups/gitlab-examples), and
watch as the Runner processes the builds just as it would on a "real" install!

### Advanced configuration

Register your Docker-based runner by following the steps described in <https://docs.gitlab.com/runner/register/index.html#docker>.

### Docker executor

#### Docker for Mac

Docker for Mac [has some networking
limitations](https://docs.docker.com/docker-for-mac/networking/), but
you can still get CI runners working with a Docker executor by using a
hostname trick. Within a container, Docker maps the
`host.docker.internal` hostname to the host IP address
(e.g. 192.168.65.2). On the host network, you can map this hostname to
the local IP address (e.g. 127.0.0.1) and use this hostname in three
different configuration files:

1. In `config/gitlab.yml`, set the `host` parameter to `host.docker.internal`.
1. In `/etc/hosts`, add an entry:

   ```plaintext
   127.0.0.1   host.docker.internal
   ```

1. In the GitLab Runner config (e.g. `~/.gitlab-runner/config.toml`), set the coordinator
   URL with this hostname and the port used by GDK (`3001` if `EE`):

   ```toml
    url = "http://host.docker.internal:3000/"
   ```

Note that all three settings must be set to ensure a number of items
work with the runner:

1. Registering the runner
1. Polling for jobs on the host network
1. Making API requests (e.g. sending artifacts) inside the container during a CI job.
1. Cloning the repository ([`CI_REPOSITORY_URL`](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html))

The `/etc/hosts` parameter is needed to make the first two items work,
since this maps `host.docker.internal` to `localhost`. The `config.toml`
changes allow the third item to work. The `gitlab.yml` changes are used
for the fourth item.

#### Using an internal, dummy interface

The trick described above is a bit of a hack and only works for Docker
for Mac, but the "proper" way to support a Docker executor is to use an
internal, dummy interface that can be used by both the host and the
container. Here's how:

1. Create an internal interface. On macOS, this will add an alias IP
   172.16.123.1 to the loopback adapter:

   ```shell
   sudo ifconfig lo0 alias 172.16.123.1
   ```

   On Linux, you can create a dummy interface:

   ```shell
   sudo ip link add dummy0 type dummy
   sudo ip address add 172.16.123.1 dev dummy0
   sudo ip link set dummy0 up
   ```

1. In `config/gitlab.yml`, set the `host` parameter to `172.16.123.1`.

1. In the GitLab Runner config (e.g. `~/.gitlab-runner/config.toml`), set the coordinator
   URL with this hostname:

   ```toml
    url = "http://172.16.123.1:3001/"
   ```

Note that for this to work across reboots, the aliased IP in step 1 needs to be run
at startup. To do this on macOS, create a file called `org.gitlab1.ifconfig.plist` at `/Library/LaunchDaemons/` containing:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.gitlab1.ifconfig</string>
    <key>RunAtLoad</key>
    <true/>
    <key>Nice</key>
    <integer>10</integer>
    <key>ProgramArguments</key>
    <array>
      <string>/sbin/ifconfig</string>
      <string>lo0</string>
      <string>alias</string>
      <string>172.16.123.1</string>
    </array>
</dict>
</plist>
```

The method to persist this dummy interface on Linux varies between distributions. On
Ubuntu 20.04, you can run:

```shell
sudo nmcli connection add type dummy ifname dummy0 ip4 172.16.123.1
```

##### Use custom hostname

To access your GDK via a hostname that points to this dummy interface (for example
`gdk.test`):

1. Set your runner to resolve the hostname by adding `runner.extra_hosts` to your `gdk.yml`.
   For example, for `gdk.test`:

   ```yaml
   runner:
     extra_hosts: ["gdk.test:172.16.123.1"]
   ```

1. Set up the custom hostname. Follow these [instructions for setting up `gdk.test`](../index.md#set-up-gdktest-hostname)
   but use the `172.16.123.1` instead of `127.0.0.1`.
