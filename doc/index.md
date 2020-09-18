# GDK documentation

GitLab Development Kit (GDK) provides a local environment for developing GitLab
and related projects.

Setting up GDK involves:

- [Installing dependencies](#install-dependencies)
- [Installing and setting up GDK](#install-and-set-up-gdk)

## Install dependencies

Before [setting up GDK](#install-and-set-up-gdk), your local environment must
have prerequisite third-party software installed and configured. Some
dependencies can be installed with a *package manager*.

You should regularly keep these dependencies up to date. Generally, the latest
versions of these dependencies work fine.

NOTE: **Note:**
Install, configure, and update all of these dependencies as a non-root user. If
you don't know what a root user is, you very likely run everything as a non-root
user already.

The process for installing dependencies depends on your operating system.
Instructions are available for:

- [macOS](#install-macos-dependencies)
- [Ubuntu](#install-ubuntu-dependencies)

[Advanced instructions](advanced.md) are also available, including instructions
for:

- [Other Linux distributions](advanced.md#install-linux-dependencies)
- [FreeBSD](advanced.md#install-freebsd-dependencies)
- [Windows 10](advanced#install-windows-10-dependencies)

### Install macOS dependencies

GDK supports macOS 10.13 (High Sierra) and higher. In macOS 10.15 (Catalina) the
default shell changed from [Bash](https://www.gnu.org/software/bash/) to
[Zsh](http://zsh.sourceforge.net). The differences are handled by setting a
`shell_file` variable based on your current shell.

To install dependencies for macOS:

1. [Install](https://brew.sh) Homebrew to get access to the `brew` command for
   package management.
1. [Install Chrome](https://www.google.com/chrome/) because the GDK depends on `chromedriver` for testing.
1. Run the following `brew` commands:

   ```shell
   brew install asdf git git-lfs libiconv pkg-config cmake openssl coreutils re2 graphicsmagick gpg icu4c exiftool sqlite runit
   brew link pkg-config
   brew pin libffi icu4c readline re2
   if [ ${ZSH_VERSION} ]; then shell_file="${HOME}/.zshrc"; else shell_file="${HOME}/.bash_profile"; fi
   echo 'export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ${shell_file}
   source ${shell_file}
   brew cask install chromedriver
   ```

1. Follow any post-installation instructions that are provided. For example,
   `asdf` has [post-install instructions](https://asdf-vm.com/#/core-manage-asdf-vm?id=add-to-your-shell).

If ChromeDriver fails to open with an error message because the developer
*cannot be verified*, create an exception for it as documented in the
[macOS documentation](https://support.apple.com/en-gb/guide/mac-help/mh40616/mac).

NOTE: **Note:**
We strongly recommend using the default installation directory for Homebrew
(`/usr/local`). This simplifies the Ruby gems installation with C extensions. If
you use a custom directory, additional work is required when installing Ruby
gems. For more information, see
[Why does Homebrew prefer I install to /usr/local?](https://docs.brew.sh/FAQ#why-does-homebrew-prefer-i-install-to-usrlocal).

### Install Ubuntu dependencies

NOTE: **Note:**
These instructions don't account for using [`asdf` for managing some dependencies](https://asdf-vm.com/#/core-manage-asdf-vm).

To install dependencies for Ubuntu, assuming you're using an active LTS release
(16.04, 18.04, 20.04) or higher:

1. Install **Yarn** from the [Yarn Debian package repository](https://yarnpkg.com/lang/en/docs/install/#debian-stable).
1. Install remaining dependencies. Modify the `GDK_GO_VERSION` with the
   major.minor version number (currently 1.14) as needed:

   ```shell
   # Add apt-add-repository helper script
   sudo apt-get update
   sudo apt-get install software-properties-common
   [[ $(lsb_release -sr) < "18.04" ]] && sudo apt-get install python-software-properties
   # This PPA contains an up-to-date version of Go
   sudo add-apt-repository ppa:longsleep/golang-backports
   # Setup path for Go
   export GDK_GO_VERSION="1.14"
   export PATH="/usr/lib/go-${GDK_GO_VERSION}/bin:$PATH"
   # This PPA contains an up-to-date version of git
   sudo add-apt-repository ppa:git-core/ppa
   sudo apt-get install git git-lfs postgresql postgresql-contrib libpq-dev redis-server \
     libicu-dev cmake g++ libre2-dev libkrb5-dev libsqlite3-dev golang-${GDK_GO_VERSION}-go ed \
     pkg-config graphicsmagick runit libimage-exiftool-perl rsync libssl-dev libpcre2-dev
   [[ $(lsb_release -sr) < "18.10" ]] && sudo apt-get install g++-8
   sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
   sudo chmod +x /usr/local/bin/minio
   ```

   > ℹ️ Ubuntu 18.04 (Bionic Beaver) and beyond doesn't have `python-software-properties` as a separate package.

## Install and set up GDK

Before attempting to use these steps, be sure you have [installed dependencies](#install-dependencies).

To get GDK up and running:

1. Install the `gitlab-development-kit` gem:

   ```shell
   gem install gitlab-development-kit
   ```

   This is required both the first time you install GDK and any time you upgrade Ruby.

1. Clone and initialize GDK using one of the following commands:

   - The default directory (`gitlab-development-kit`):

     ```shell
     gdk init
     ```

   - A custom directory. For example, to initialize `gdk`, run:

     ```shell
     gdk init gdk
     ```

1. Install GDK components in the GDK directory:

   1. Navigate to the newly-created GDK directory.
   1. Run `make bootstrap` to install remaining dependencies. If you receive an error
      message that begins with: **Authenticity of checksum file can not be assured!**:
      1. Follow the [`asdf-nodejs` Install section instructions](https://github.com/asdf-vm/asdf-nodejs#install).
      1. Run `make bootstrap` after you resolve the problem.
   1. Make the newly install PostgreSQL headers (assumes PostgreSQL 11.8) available to the system by
      running:

      ```shell
      bundle config build.pg --with-opt-dir="${HOME}/.asdf/installs/postgres/11.8"
      ```

   1. Install the necessary components (repositories, Ruby gem bundles, and configuration) using
      `gdk install`. Use one of the following methods:

      - For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org) we
        recommend developing against the GitLab project (the default):

        - Cloning `gitlab` using SSH (recommended), run:

          ```shell
          gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
          ```

        - Cloning `gitlab` using HTTPS, run:

          ```shell
          gdk install
          ```

        Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
        The clone process uses [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

      - Other options, in order of recommendation:
        - Install using [a GitLab fork](#install-using-your-own-gitlab-fork).
        - Install using [the GitLab FOSS project](#install-using-gitlab-foss-project).

### Install using GitLab FOSS project

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab FOSS](https://gitlab.com/gitlab-org/gitlab-foss).

After installing the `gitlab-development-kit` gem and initializing a GDK
directory, for:

- Cloning `gitlab-foss` using SSH, run:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab-foss.git
  ```

- Cloning `gitlab-foss` using HTTPS, run:

  ```shell
  gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-foss.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk
space. The clone process uses [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Install using your own GitLab fork

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab](https://gitlab.com/gitlab-org/gitlab).

After installing the `gitlab-development-kit` gem and initializing a GDK
directory, for:

- Cloning your `gitlab` fork using SSH, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=git@gitlab.com:<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

- Cloning your `gitlab` fork using HTTPS, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=https://gitlab.com/<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

The `set-gitlab-upstream` script creates a remote named `upstream` for
[the canonical GitLab repository](https://gitlab.com/gitlab-org/gitlab). It also
modifies `gdk update` (See [Update GitLab](gdk_commands.md#update-gitlab))
to pull down from the upstream repository instead of your fork, making it easier
to keep up-to-date with the project.

If you want to push changes from upstream to your fork, run `gdk update` and then
`git push origin` from the `gitlab` directory.

## Set up `gdk.test` hostname

`gdk.test` is the standard for referring to the local GDK instance in
documentation steps and GDK tools. To set up `gdk.test` as a hostname:

1. Map `gdk.test` to 127.0.0.1. For example, add the following to `/etc/hosts`:

   ```plaintext
   127.0.0.1 gdk.test
   ```

1. Add the following to `gdk.yml`:

   ```yaml
   hostname: gdk.test
   ```

1. Reconfigure GDK:

   ```shell
   gdk reconfigure
   ```

## Resolve installation errors

During the `gdk install` process, you may encounter some dependency-related
errors. If these errors occur:

- Run `gdk doctor`, which can detect problems and offer possible solutions.
- Refer to the [troubleshooting page](troubleshooting.md).
- [Open an issue in the GDK tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).

## Use GitLab Enterprise features

Instructions to generate a developer license can be found in the
[onboarding documentation](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee).

The license key generator is available only for GitLab team members, who should
use the **Sign in with GitLab** link using their `dev.gitlab.org` account.

For information about adding your license to GitLab, see
[Activate GitLab EE with a license](https://docs.gitlab.com/ee/user/admin_area/license.html)

## Post-installation

After successful installation, see:

- [GDK commands](gdk_commands.md).
- [GDK configuration](configuration.md).

After installation, [learn how to use GDK](howto/index.md) to enable other
features.

## Update GDK

For information about updating GDK, see [Update GDK](gdk_commands.md#update-gdk).

## Create new GDK

After you have set up GDK initially, you can create new *fresh installations*.
You might do this if you have problems with existing installation that are
complicated to fix, and you just need to get up and running quickly. To create a
fresh installation:

1. In the parent folder for GDK, run
   [`gdk init <new directory>`](#initialize-a-new-gdk-directory).
1. In the new directory, run [`gdk install`](#install-gdk-components).
