# Install and configure GDK

[[_TOC_]]

GitLab Development Kit (GDK) provides a local environment for developing GitLab and related projects. For example:

- [Gitaly](https://gitlab.com/gitlab-org/gitaly).
- [GitLab Docs](https://gitlab.com/gitlab-org/gitlab-docs).

To ensure a smooth installation of GDK, you should delete any previously cloned repositories. This prevents conflicts or errors that may arise during the installation process.

To install GDK, you must:

1. Install prerequisites.
1. Install dependencies and the GDK:
   - In a single step with the [one-line installation](#one-line-installation). This method installs dependencies
     and the GDK with one command.
   - In two steps with the [simple installation](#simple-installation). This method separates dependency installation
     and GDK installation, for more control and customization. When using the simple installation method, you:

     1. Install dependencies [using `asdf`](#install-dependencies-using-asdf) or [manually](#install-dependencies-manually).
     1. [Use GDK to install GitLab](#use-gdk-to-install-gitlab).

Use a [supported operating system](../README.md#supported-platforms).

## Install prerequisites

You must have [Git](https://git-scm.com/downloads) and `make` installed to install GDK.

### macOS

The macOS installation requires Homebrew as well as Git and `make`. Git and `make` are installed by default, but
Homebrew must be installed manually. Follow the guide at [brew.sh](https://brew.sh/).

If you have upgraded macOS, install the Command Line Tools package for Git to work:

```shell
xcode-select --install
```

### Ubuntu or Debian

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

  1. Install `git` and `make`:

     ```shell
     sudo apt install git make
     ```

### Arch and Manjaro Linux

Update the list of available packages and install `git` and `make`:

```shell
sudo pacman -Syu git make
```

### Other platforms

Install using your system's package manager.

## One-line installation

The one-line installation:

1. Prompts the user for a GDK directory name. The default is `gitlab-development-kit`.
1. From the current working directory, clones the GDK project into the specified directory.
1. Installs `asdf` and necessary `asdf` plugins.
1. Runs `gdk install`.
1. Runs `gdk start`.

Before running the one-line installation, ensure [the prerequisites are installed](#install-prerequisites).
Then install GDK with:

```shell
curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/install" | bash
```

If you have any post-installation problems, see [Resolve installation errors](#resolve-installation-errors). A common
post-installation problem is [incomplete `asdf` installation](troubleshooting/asdf.md#error-command-not-found-gdk).

## Simple installation

After prerequisites are installed, you can install GDK dependencies and GDK itself.

### Install dependencies

Before [using GDK to install GitLab](#use-gdk-to-install-gitlab), you must install and configure some third-party
software, either:

- [Using `asdf`](#install-dependencies-using-asdf).
- [Manually](#install-dependencies-manually).

If you've previously [managed your own dependencies](advanced.md), you can [migrate to `asdf`](migrate_to_asdf.md)
so that GDK can manage dependencies for you.

#### Install dependencies using `asdf`

Installing and managing dependencies automatically lets GDK manage dependencies for you using
[`asdf`](https://asdf-vm.com/#/core-manage-asdf). Note that on a new workstation, you should be
sure to [install `asdf`](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) before proceeding, as it is not installed by the `make` script below.

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

#### Install dependencies manually

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

### Use GDK to install GitLab

To install GitLab by using GDK, use one of these methods:

- For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org), you should install
  using SSH:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
  ```

- Otherwise, install using HTTPS:

  ```shell
  gdk install
  ```

If `gdk install` doesn't work, see [Resolve installation errors](#resolve-installation-errors). A common
installation problem is [incomplete `asdf` installation](troubleshooting/asdf.md#error-command-not-found-gdk).

Use `gdk install shallow_clone=true` for faster clones that consumes less disk-space. The clone
process uses [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

Use `gdk install blobless_clone=false` for clones without any `git clone`
arguments. `git clone` commands will consume more disk-space and be slower
however.

### Use GDK to install GitLab FOSS

If you want to run GitLab FOSS, install GDK using
[the GitLab FOSS project](install_alternatives.md#install-using-gitlab-foss-project).

### Use GDK to install your own GitLab fork

If you want to run GitLab from your own fork, install GDK using
[your own GitLab fork](install_alternatives.md#install-using-your-own-gitlab-fork).

## Set up `gdk.test` hostname

You should set up `gdk.test` as a local hostname. For more information, see
[Local network binding](howto/local_network.md).

## Resolve installation errors

During the `gdk install` process, you may encounter some dependency-related
errors. If these errors occur:

- Run `gdk doctor`, which can detect problems and offer possible solutions.
- Refer to the [troubleshooting page](troubleshooting/index.md).
- [Open an issue in the GDK tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).
- Run `gdk pristine` to restore your GDK to a pristine state.

## Use GitLab Enterprise features

For instructions on how to generate a developer license, see [Developer onboarding](https://handbook.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses).

The developer license is generated for you to get access to [Premium or Ultimate](https://about.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/) features in your GDK. You must add this license to your GDK instance, not your GitLab.com account.

### Configure developer license in GDK

To configure your developer license in GDK:

1. [Add your developer license](https://docs.gitlab.com/ee/administration/license_file.html) to GitLab running in GDK.
1. Add the following configuration to your `gdk.yml` depending on your license type:

   - If you're using a license generated from the production Customers Portal, run:

     ```shell
     gdk config set license.customer_portal_url https://customers.gitlab.com
     gdk config set license.license_mode prod
     ```

   - To use custom settings, add:

     ```shell
     gdk config set license.customer_portal_url <customer portal url>
     gdk config set license.license_mode <license mode>
     ```

1. Run `gdk reconfigure` to reconfigure GDK.
1. Run `gdk restart` to restart GDK.

If you're using a license generated from the staging Customers Portal, you don't need to add anything to `gdk.yml`. The following environment variables are
already set by default:

```shell
export GITLAB_LICENSE_MODE=test
export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
```

## Post-installation

After successful installation, see:

- [GDK commands](gdk_commands.md).
- [GDK configuration](configuration.md).

After installation, [learn how to use GDK](howto/index.md) to enable other features.

## Update GDK

For information about updating GDK, see [Update GDK](gdk_commands.md#update-gdk).

## Create new GDK

After you have set up GDK initially, you can create new *fresh installations*. You might do this if
you have problems with existing installation that are complicated to fix. You can get up and running
quickly again by:

1. In the parent folder for GDK, run [`git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git`](#install-dependencies-manually).
1. In the new directory, run [`gdk install`](#use-gdk-to-install-gitlab).
