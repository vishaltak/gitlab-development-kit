# GitLab Development Kit (GDK)

[![build status](https://gitlab.com/gitlab-org/gitlab-development-kit/badges/main/pipeline.svg)](https://gitlab.com/gitlab-org/gitlab-development-kit/pipelines)

The GitLab Development Kit (GDK) installs GitLab on your workstation. GDK
manages GitLab requirements, development tools and databases.

The GDK is used by GitLab team members and contributors to test changes
locally to speed up the time to make successful contributions.

## Goals

- Provide tools to install, update, and develop against a local GitLab instance.
- Automate installing [required software](https://docs.gitlab.com/ee/install/requirements.html#software-requirements).
- Only manage projects, software, and services that may be needed to run a GitLab instance.
- Out of the box, only enable the services GitLab strictly requires to operate.
- Support native operating systems as listed below.

## Installation

You can install GDK using the following methods. Some are:

- Supported and frequently tested.
- Not supported, but we welcome merge requests to improve them.

### Supported methods

The following installation methods are supported, actively maintained, and tested:

#### Local

Requires at least 16 GB RAM and 15 GB disk space.
Available for [supported platforms](#supported-platforms).

- [One-line installation](doc/index.md#one-line-installation).
- [Simple installation](doc/index.md#simple-installation).
- [GDK-in-a-box](doc/gdk_in_a_box.md). Requires at least 30 GB disk space.

#### Remote

- [GitLab remote development workspaces](doc/howto/gitlab-remote-development.md).
- [Gitpod](doc/howto/gitpod.md).

### Supported platforms

| Operating system | Versions                       |
|:-----------------|:-------------------------------|
| macOS            | 14, 13, 12 (1)                 |
| Ubuntu           | 22.04, 21.10               |
| Fedora           | 36 (2), 35                     |
| Debian           | 13, 12                         |
| Arch             | latest                         |
| Manjaro          | latest                         |

- (1) We follow [Apple's supported versions](https://endoflife.date/macos).

The list of platforms includes operating systems that run in a Windows Subsystem for Linux (WSL) environment.

### Unsupported methods

The following documentation is provided for those who can benefit from it, but aren't
supported installation methods:

- [Advanced installation](doc/advanced.md) on your local system. Requires at least
  8 GB RAM and 12 GB disk space.
- [minikube](doc/howto/kubernetes/minikube.md).

## Post-installation

- [Use GDK](doc/howto/index.md).
- [Update an existing installation](doc/index.md#update-gdk).
- [Login credentials (root login and password)](doc/gdk_commands.md#get-the-login-credentials).

### Using SSH remotes

GDK defaults to HTTPS instead of SSH when cloning the repositories. With HTTPS, you can still use GDK without a GitLab.com
account or an SSH key. However, if you have a GitLab.com account and already
[added your SSH key](https://docs.gitlab.com/ee/user/ssh.html#add-an-ssh-key-to-your-gitlab-account) to your account,
you can configure `git` to rewrite the URLs to use SSH via the following configuration change:

```shell
git config --global url.'git@gitlab.com:'.insteadOf 'https://gitlab.com/'
```

NOTE:
This command configures `git` to use `SSH` for all GitLab.com URLs.

## FAQ

### Why don't we Dockerize or containerize GDK, or switch to GCK as the preferred tool?

- The majority of GDK users have macOS as their primary operating system, which is
  supported by Docker and other containerization tools but usually requires a virtual machine (VM).
  Running and managing a VM adds to the overall complexity.
- The performance of Docker or containerization on macOS is still unpredictable.
  It's getting better all the time, but for some users (both GitLab team members and our community)
  it may prove to be a blocker.
- The ability to debug problems is another issue as getting to the root cause of
  a problem could prove more challenging due to the different execution and operating contexts
  of Docker or other containerization tools.
- For users that run non-Linux operating systems, running Docker or other containerization tools
  have their own set of hardware requirements which could be another blocker.

## Getting help

- We encourage you to [create a new issue](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/new).
- GitLab team members can use the `#gdk` channel on the GitLab Slack workspace.
- Review the [troubleshooting information](doc/troubleshooting).
- Wider community members can use the following:
  - [GitLab community Discord](https://discord.gg/gitlab).
  - [GitLab Forum](https://forum.gitlab.com/c/community/39).

## Contributing to GitLab Development Kit

Contributions are welcome; see [`CONTRIBUTING.md`](CONTRIBUTING.md)
for more details.

### Install Lefthook locally

Please refer to the [Lefthook page](doc/howto/lefthook.md).

## License

The GitLab Development Kit is distributed under the MIT license; see the
[LICENSE](LICENSE) file.
