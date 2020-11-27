# GitLab Development Kit (GDK)

[![build status](https://gitlab.com/gitlab-org/gitlab-development-kit/badges/master/pipeline.svg)](https://gitlab.com/gitlab-org/gitlab-development-kit/pipelines)

Configure and manage a [GitLab](https://about.gitlab.com) development
environment.

Read on for installation instructions, or skip to the
[usage documentation](doc/howto/index.md).

## Overview

The GitLab Development Kit (GDK) helps you install a GitLab instance on your
workstation. It includes a collection of GitLab requirements, such as Ruby,
Node.js, Go, PostgreSQL, Redis, and more.

The GDK is recommended for anyone contributing to the GitLab codebase, whether a
GitLab team member or a member of the wider community. It allows you to test
your changes locally on your workstation in an isolated manner. This can speed
up the time it takes to make successful contributions.

For help with the GDK:

- GitLab team members can use the `#gdk` channel on the GitLab Slack workspace.
- Wider community members can use the [Gitter contributors room](https://gitter.im/gitlab/contributors)
  or [GitLab Forum](https://forum.gitlab.com/c/community/community-contributions/15).

## Contributing to GitLab Development Kit

Contributions are welcome; see [`CONTRIBUTING.md`](CONTRIBUTING.md)
for more details.

## System requirements

The following are the supported systems and recommended hardware required to run GDK
effectively:

| Operating System | Architecture | Version(s) | RAM | Disk |
| ---------------- | ------------ | ---------- | --- | ---- |
| macOS            | amd64 | Big Sur (11), Catalina (10.15), Mojave (10.14) | 8GB | 12GB |
| Ubuntu Linux     | amd64 | 20.10 (Groovy Gorilla), 20.04 LTS (Focal Fossa), 18.04 LTS (Bionic Beaver) | 8GB | 12GB |
| Debian Linux     | amd64 | 10 (Buster), 9 (Stretch), 8 (Jessie) | 8GB | 12GB |

## Getting started

The preferred way to use GitLab Development Kit is to install Ruby and its
dependencies on your native operating system. We strongly recommend the native
install, since it is much faster than a virtualized one. Due to heavy IO
operations, a virtualized installation is much slower running the app and the
tests.

### Native install (recommended)

1. [Install dependencies](doc/index.md#install-dependencies)
1. [Install and set up GDK](doc/index.md#install-and-set-up-gdk)

### Vagrant install

You can install GDK under a
[virtualized environment using Vagrant with Virtualbox or Docker](doc/howto/vagrant.md).

### Minikube install

You can also install GDK on [Minikube](https://github.com/kubernetes/minikube);
see [Kubernetes docs](doc/howto/kubernetes.md).

## How to use GDK

After installation, [learn how to use GDK](doc/howto/index.md).

## How to update GDK

If you have an old installation, [learn how to update your existing GDK installation](doc/index.md#update-gdk).

## Design goals

- Get the user started, and don't try to take care of everything.
- Run everything as your 'desktop' user on your development computer.
- It's acceptable to leave some actions for the user to complete (for example,
  installing Ruby).

## Components included

A list of which components are included in the GDK, and configuration
instructions (if needed) are available in the
[architecture components list](https://docs.gitlab.com/ee/development/architecture.html#component-list).

## Differences with production

- `gitlab-workhorse` doesn't serve static files.
- C compiler needed to run `bundle install` (not needed with Omnibus).
- GitLab can rewrite its program code and configuration data (read-only with
  Omnibus).
- 'Assets' (JavaScript/CSS files) are generated on-the-fly (pre-compiled at
  build time with Omnibus).
- Gems (libraries) for development and functional testing get installed and
  loaded.
- No unified configuration management for GitLab and `gitlab-shell`
  (handled by Omnibus).
- No privilege separation between Ruby, PostgreSQL, and Redis.
- No easy upgrades.
- Need to download and compile new gems (`bundle install`) on each upgrade.

Note that for some changes to some configuration and routes, run
`gdk restart rails-web` so the running configuration reflects the change.

## License

The GitLab Development Kit is distributed under the MIT license; see the
[LICENSE](LICENSE) file.
