# Using GitLab Runner with the GDK

Most features of [GitLab CI/CD](http://docs.gitlab.com/ee/ci/) need a
[Runner](http://docs.gitlab.com/ee/ci/runners/README.html) to be registered with
the GitLab installation. This HOWTO will take you through the necessary steps to
do so when GitLab is running under GDK.

## Set up GitLab Runner

Unless you want to make changes to the Runner, it's easiest to install a binary
package. Follow the
[installation instructions](https://docs.gitlab.com/runner/install/)
for your operating system
([Linux](https://docs.gitlab.com/runner/install/linux-repository.html),
[OSX](https://docs.gitlab.com/runner/install/osx.html),
[Windows](https://docs.gitlab.com/runner/install/windows.html)).

To build from source, you'll need to set up a development environment manually -
GDK doesn't manage it for you. The official GitLab Runner repository is
[here](https://gitlab.com/gitlab-org/gitlab-runner); just follow
[the development instructions](https://docs.gitlab.com/runner/development/).

## Set up GitLab

Start by [preparing your computer](../prepare.md) and
[setting up GDK](../index.md). In some configurations, GitLab Runner needs access
to GitLab from inside a Docker container, or even another machine, which isn't
supported in the default configuration.

### Default configuration

By default, the "shell" executor is used. If you wish to use the "Docker" executor
type, please see [Docker configuration](#Docker_configuration) below.

With GDK running:

1. Navigate to `http://localhost:3000/admin/runners` (log in as root)
1. Make note of the `Registration token` under the 'Set up a shared Runner manually' section.
1. Add the following into your `gdk.yml`:

   ```yaml
   runner:
     enabled: true
     token: <your registration token>
   ```

1. Reconfigure and restart GDK:

   ```shell
   gdk reconfigure
   gdk restart
   ```

1. The `runner` service should now be running and waiting for your GitLab instance
to be up.

### Docker configuration

Follow the steps to [install Docker](https://docs.docker.com/get-docker/) for your
platform.

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
   ifconfig dummy0 172.16.123.1
   ```

1. In `config/gitlab.yml`, set the `host` parameter to `172.16.123.1`.

1. In the GitLab Runner config (e.g. `~/.gitlab-runner/config.toml`), set the coordinator
   URL with this hostname:

   ```toml
    url = "http://172.16.123.1:3001/"
   ```

Note that for this to work across reboots, the aliased IP in step 1 needs to be run
at startup.

#### Configure the GDK

Once you've installed Docker, we need to configure GitLab to bind to all
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

1. Navigate to `http://localhost:3000/admin/runners` (log in as root)
1. Make note of the `Registration token` under the 'Set up a shared Runner manually' section.
1. Add the following into your `gdk.yml`:

   ```yaml
   runner:
     enabled: true
     executor_type: docker
     token: <your registration token>
   ```

1. Reconfigure and restart GDK:

   ```shell
   gdk reconfigure
   gdk restart
   ```

1. The `runner` service should now be running and waiting for your GitLab instance
to be up.

Navigate to `http://<IP address>:3000/gitlab-org/gitlab-test`.
If the URL doesn't work, repeat the last step and pick a different IP.

Once there, ensure that the HTTP clone URL is `http://<ip>:3000/gitlab-org/gitlab-test.git`.
If it points to `localhost` instead, `gitlab/config/gitlab.yml` is incorrect.

Finally, navigate to `http://<ip>:3000/admin/runners` (log in as root) and make
a note of the `Registration token`.

Register your Docker-based runner by following the steps described in <https://docs.gitlab.com/runner/register/index.html#docker>.
