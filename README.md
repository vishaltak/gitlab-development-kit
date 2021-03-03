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

## System requirements

[Simple installation of dependencies](doc/index.md) is available for these operating systems:

| Operating System | Architecture | Version(s) | RAM | Disk |
| ---------------- | ------------ | ---------- | --- | ---- |
| macOS            | <ul><li>amd64</li><li>arm64 (Apple Silicon, under Rosetta 2)</li></ul> | <ul><li>Big Sur (11)</li><li>Catalina (10.15)</li><li>Mojave (10.14)</li><ul> | 8GB | 12GB |
| Ubuntu Linux     | <ul><li>amd64</li></ul> | <ul><li>20.10 (Groovy Gorilla)</li><li>20.04 LTS (Focal Fossa)</li><li>18.04 LTS (Bionic Beaver)</li><ul> | 8GB | 12GB |
| Debian Linux     | <ul><li>amd64</li></ul> | <ul><li>10 (Buster)</li><li>9 (Stretch)</li><ul> | 8GB | 12GB |
| Arch Linux     | <ul><li>amd64</li></ul> | <ul><li>latest</li> | 8GB | 12GB |
| Manjaro Linux     | <ul><li>amd64</li></ul> | <ul><li>latest</li> | 8GB | 12GB |

[Advanced installation of dependencies](doc/advanced.md) is available for these systems, and may be available for other systems.

## Getting started

### How to install GDK

The default method of installing GDK is [on your native operating system](doc/index.md).

The GDK can also be installed via [Vagrant](doc/howto/vagrant.md), [Minikube](doc/howto/kubernetes/minikube.md), and [Gitpod](doc/howto/gitpod.md).

### How to use GDK

After installation, [learn how to use GDK](doc/howto/index.md).

### How to update GDK

If you have an old installation, [learn how to update your existing GDK installation](doc/index.md#update-gdk).

## Getting help

- We encourage you to [create a new issue](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/new).
- GitLab team members can use the `#gdk` channel on the GitLab Slack workspace.
- Wider community members can use the [Gitter contributors room](https://gitter.im/gitlab/contributors)
  or [GitLab Forum](https://forum.gitlab.com/c/community/community-contributions/15).

## Contributing to GitLab Development Kit

Contributions are welcome; see [`CONTRIBUTING.md`](CONTRIBUTING.md)
for more details.

## License

The GitLab Development Kit is distributed under the MIT license; see the
[LICENSE](LICENSE) file.
