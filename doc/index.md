# Install and configure GDK

GitLab Development Kit (GDK) provides a local environment for developing GitLab
and related projects.

## Install prerequisites

Installation requires [Git](https://git-scm.com/downloads) and `make` are installed.

### macOS

`git` and `make` are installed by default. Homebrew must be installed. Follow the guide at [brew.sh](https://brew.sh/).

### Ubuntu/Debian

  1. Update the list of available packages:

     ```shell
     sudo apt update
     ```

  1. Add an `apt` repository for the latest version of Git.

     - For Ubuntu, install `add-apt-repository` and add a PPA repository:

       ```shell
       sudo apt install software-properties-common
       sudo add-apt-repository ppa:git-core/ppa
       ```

     - For Debian, add a [backport repository](https://backports.debian.org/Instructions/) for your
       Debian version.

  1. Install Git and Make:

     ```shell
     sudo apt install git make
     ```

### Arch and Manjaro Linux

Update the list of available packages and install Git and Make:

```shell
sudo pacman -Syu git make
```

### Other

Install using your system's package manager.

## One-line installation

The one-line installation:

- Clones the GDK project into a new `gitlab-development-kit` directory in the current working
  directory.
- Installs `asdf` and necessary `asdf` plugins.
- Runs `gdk install`.
- Runs `gdk start`.

1. Follow [dependency installation instructions](index.md#install-prerequisites).

1. Install GDK:

    ```shell
    curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/install" | bash
    ```

If you have any post-installation problems, see [Resolve installation errors](#resolve-installation-errors). A common
post-installation problem is [incomplete `asdf` installation](troubleshooting/asdf.md#error-command-not-found-gdk).

## Simple Installation

After prerequisites are installed, you can install GDK dependencies and GDK itself.

### Install dependencies

Before [installing GDK](#install-gdk), your local environment must have third-party software
installed and configured. These can be installed and managed automatically
[using `asdf`](#automatically-using-asdf) or [manually](#manually).

If you've previously [managed your own dependencies](advanced.md), you can
[migrate to `asdf`](migrate_to_asdf.md) to allow GDK to manage dependencies for you.

#### Automatically using `asdf`

Installing and managing dependencies automatically lets GDK manage dependencies for you using
[`asdf`](https://asdf-vm.com/#/core-manage-asdf):

1. Clone the `gitlab-development-kit` repository into your preferred location, if you haven't previously:

   ```shell
   git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git
   ```

1. Change into the GDK project directory:

   ```shell
   cd gitlab-development-kit
   ```

1. Install all dependencies using `asdf`:

   ```shell
   make bootstrap
   ```

1. If migrating from other version managers like RVM or rbenv, you can set
   [`legacy_version_file`](https://asdf-vm.com/manage/configuration.html#legacy-version-file) in `.asdfrc` to load the
   Ruby version from a different configuration file like `.ruby-version`.

#### Manually

Use your operating system's package manager to install and managed dependencies.
[Advanced instructions](advanced.md) are available to help. These include instructions for macOS,
Ubuntu, and Debian (and other Linux distributions), FreeBSD, and Windows 10. You should
regularly update these. Generally, the latest versions of these dependencies work fine. Install,
configure, and update all of these dependencies as a non-root user. If you don't know what a root
user is, you very likely run everything as a non-root user already.

After installing GDK dependencies:

1. Clone the `gitlab-development-kit` repository into your preferred location:

   ```shell
   git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git
   ```

   The default directory created is `gitlab-development-kit`. This can be customized by appending a different directory name to the `git clone` command.

1. Change into the GDK project directory:

   ```shell
   cd gitlab-development-kit
   ```

1. Install the `gitlab-development-kit` gem:

   ```shell
   gem install gitlab-development-kit
   ```

1. Install all the Ruby dependencies:

   ```shell
   bundle install
   ```

### Install GDK

Install GDK by cloning and configuring GitLab and other projects using
`gdk install`. Use one of the following methods:

- For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org), we
  recommend installing using SSH:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
  ```

- Otherwise, install using HTTPs:

    ```shell
    gdk install
    ```

If `gdk install` doesn't work, see [Resolve installation errors](#resolve-installation-errors). A common
installation problem is [incomplete `asdf` installation](troubleshooting/asdf.md#error-command-not-found-gdk).

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space. The clone
process uses [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Install GDK using GitLab FOSS project

If you want to run GitLab FOSS, install GDK using
[the GitLab FOSS project](install_alternatives.md#install-using-gitlab-foss-project).

### Install GDK using your own GitLab fork

If you want to run GitLab from your own fork, install GDK using
[your own GitLab fork](install_alternatives.md#install-using-your-own-gitlab-fork).

## Set up `gdk.test` hostname

We recommend setting up `gdk.test` as a local hostname. For more information, see
[Local network binding](howto/local_network.md).

## Resolve installation errors

During the `gdk install` process, you may encounter some dependency-related
errors. If these errors occur:

- Run `gdk doctor`, which can detect problems and offer possible solutions.
- Refer to the [troubleshooting page](troubleshooting/index.md).
- [Open an issue in the GDK tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).
- Run `gdk pristine` to restore your GDK to a pristine state.

## Use GitLab Enterprise features

For instructions on how to generate a developer license, see [Developer onboarding](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses).

The developer license is generated for you to get access to [Premium or Ultimate](https://about.gitlab.com/handbook/marketing/strategic-marketing/tiers/) features in your GDK. You must add this license to your GDK instance, not your GitLab.com account.

For information about adding your license to GitLab, see [Activate GitLab EE with a license file or key](https://docs.gitlab.com/ee/user/admin_area/license_file.html).

## Post-installation

After successful installation, see:

- [GDK commands](gdk_commands.md).
- [GDK configuration](configuration.md).

After installation, [learn how to use GDK](howto/index.md) to enable other
features.

## Update GDK

For information about updating GDK, see [Update GDK](gdk_commands.md#update-gdk).

## Create new GDK

After you have set up GDK initially, you can create new *fresh installations*. You might do this if
you have problems with existing installation that are complicated to fix. You can get up and running
quickly again by:

1. In the parent folder for GDK, run [`git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git`](#manually).
1. In the new directory, run [`gdk install`](#install-gdk).
