# GDK documentation

GitLab Development Kit (GDK) provides a local environment for developing GitLab
and related projects.

Setting up GDK involves:

- [Installing Git and Make](#install-git-and-make).
- [Installing dependencies](#install-dependencies).
- [Installing and setting up GDK](#install-and-set-up-gdk).

## Install Git and Make

Because GDK requires them, you must ensure `git` and `make` are available. If you're on:

- macOS, `git` and `make` are installed by default.
- Ubuntu/Debian, run the following to install `git` and `make`:

   ```shell
   apt-get update && apt-get install git make
   ```

- Other systems, use your system's package manager to install them.

## Install dependencies

Before [setting up GDK](#install-and-set-up-gdk), your local environment must
have prerequisite third-party software installed and configured. GDK dependencies are:

- [Git](https://git-scm.com)
- [Go](https://golang.org)
- [MinIO](https://min.io)
- [Node.js](https://nodejs.org)
- [PostgreSQL](https://www.postgresql.org)
- [Redis](https://redis.io)
- [Ruby](https://www.ruby-lang.org)
- [Yarn](https://yarnpkg.com)

These can be installed and managed:

- The recommended way by letting GDK manage dependencies for you using
  [`asdf`](https://asdf-vm.com/#/core-manage-asdf). The following platforms are supported:
  - macOS
  - Ubuntu
  - Debian
- By you using your operating system's package manager. You should regularly keep these
  dependencies up to date. Generally, the latest versions of these dependencies work fine. Install,
  configure, and update all of these dependencies as a non-root user. If you don't know what a root
  user is, you very likely run everything as a non-root user already.

For those manually managing their dependencies, [advanced instructions](advanced.md) are also
available, including instructions for:

- [macOS](advanced.md#macos)
- [Ubuntu](advanced.md#ubuntu)
- [Debian](advanced.md#debian)
- [Other Linux distributions](advanced.md#install-other-linux-dependencies)
- [FreeBSD](advanced.md#install-freebsd-dependencies)
- [Windows 10](advanced.md#install-windows-10-dependencies)

### From self-managed dependencies to GDK-managed dependencies using `asdf`

If you've previously [managed your own dependencies](advanced.md), you might want to let GDK manage
dependencies for you using `asdf`. The following are instructions to help you remove previously
installed self-managed dependencies so that they don't conflict with `asdf`:

1. Uninstall dependencies you installed with your operating system's package manager. For example,
   for macOS:

   ```shell
   brew uninstall go postgresql@12 minio/stable/minio redis yarn
   ```

- Uninstall your Ruby dependency manager, usually `rvm` or `rbenv`. If you're unsure which Ruby
  dependency manager you were using, run `which ruby` at the command line. The dependency manager in
  use should be indicated by the output. For more information, see:
  - [`rbenv` uninstall](https://github.com/rbenv/rbenv#uninstalling-rbenv) documentation.
  - [`rvm` removal](https://rvm.io/support/troubleshooting) documentation.
- Uninstall your Node dependency manager (usually `nvm` or `brew`). If you're unsure which Ruby
  dependency manager you were using, run `which node` at the command line. The dependency manager in
  use should be indicated by the output:
  - If using `nvm`, see [uninstalling `nvm` documentation](https://github.com/nvm-sh/nvm#uninstalling--removal).
  - If not using `nvm`, try running `brew uninstall node`.
- Remove configuration from your home directory relating to these dependency managers. For example:
  - `~/.rvm`.
  - `~/.rbenv`.
  - `~/.nvm`.
- Remove shell-related configuration settings related to your dependency managers in files such as:
  - `.bashrc` for `bash`.
  - `.zshrc` for `zsh`.

It's possible:

- You have more than one dependency manager handling the same dependency. In this case, repeat the
  process for each. For example, removing an `nvm`-managed `node` might reveal a `brew`-managed
  `node`.
- That your system provides a dependency also (for example, macOS comes with Ruby itself). Don't
  try to remove these because `asdf` is less likely to conflict with these.

## Install and set up GDK

Before attempting to use these steps:

- Ensure [`git` and `make` are installed](#install-git-and-make).
- Ensure you have [installed dependencies](#install-dependencies), if necessary.

To install GDK:

- With GDK managing your dependencies using `asdf`:

  1. Clone the `gitlab-development-kit` repository into your preferred location, if you haven't
     previously:

     ```shell
     git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git
     ```

  1. Change into the GDK project directory:

     ```shell
     cd gitlab-development-kit
     ```

  1. Run:

     ```shell
     make bootstrap
     ```

- Having managed your own dependencies:

  1. Install the `gitlab-development-kit` gem:

     ```shell
     gem install gitlab-development-kit
     ```

  1. Initialize a GDK directory (this also checks out the project) by running the following in your
     preferred location:

     ```shell
     gdk init
     ```

     The default directory created is `gitlab-development-kit`. This can be customized by appending
     a different directory name to the command.

  1. Change into the newly-created GDK directory.

Complete GDK installation by cloning and configuring GitLab and other projects
using `gdk install`. Use one of the following methods:

- For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org) we
  recommend developing against the GitLab project (the default). To:
  - Clone `gitlab` using SSH (recommended), run:

    ```shell
    gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
    ```

  - Clone `gitlab` using HTTPS, run:

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

After cloning the `gitlab-development-kit` project and running `make bootstrap`, to:

- Clone `gitlab-foss` using SSH, run:

  ```shell
  gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab-foss.git
  ```

- Clone `gitlab-foss` using HTTPS, run:

  ```shell
  gdk install gitlab_repo=https://gitlab.com/gitlab-org/gitlab-foss.git
  ```

Use `gdk install shallow_clone=true` for a faster clone that consumes less disk
space. The clone process uses [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Install using your own GitLab fork

> Learn [how to create a fork](https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html#creating-a-fork)
> of [GitLab](https://gitlab.com/gitlab-org/gitlab).

After cloning the `gitlab-development-kit` project and running `make bootstrap`, to:

- Clone your `gitlab` fork using SSH, run:

  ```shell
  # Replace <YOUR-NAMESPACE> with your namespace
  gdk install gitlab_repo=git@gitlab.com:<YOUR-NAMESPACE>/gitlab.git
  support/set-gitlab-upstream
  ```

- Clone your `gitlab` fork using HTTPS, run:

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
