# Install GDK

GitLab Development Kit (GDK) provides a local environment for developing GitLab
and related projects.

## Install prerequisites

Installation requires `git` and `make` are installed.

### macOS

`git` and `make` are installed by default, proceed to the next section.

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

### Other

Install via your system's package manager.

## Install dependencies and GDK

### Install dependencies

Before [setting up GDK](#install-and-set-up-gdk), your local environment must
have third-party software installed and configured. These can be installed and
managed automatically [using `asdf`](#automatically-using-asdf) or [manually](#manually).

#### Automatically using asdf

Installing and managing dependencies automatically lets GDK manage dependencies for you using
[`asdf`](https://asdf-vm.com/#/core-manage-asdf):

1. Clone the `gitlab-development-kit` repository into your preferred location, if you haven't
   previously:

    ```shell
    git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git
    ```

1. Change into the GDK project directory:

    ```shell
    cd gitlab-development-kit
    ```

1. Install all dependencies via `asdf`:

    ```shell
    make bootstrap
    ```

#### Manually

By using your operating system's package manager. You should regularly keep these
dependencies up to date. Generally, the latest versions of these dependencies work fine. Install,
configure, and update all of these dependencies as a non-root user. If you don't know what a root
user is, you very likely run everything as a non-root user already.

For those manually managing their dependencies, [advanced instructions](advanced.md) are also
available, including instructions for, macOS, Ubuntu and Debian (and other Linux distributions),
FreeBSD, and Windows 10.

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

1. Change into the GDK project directory:

    ```shell
    cd gitlab-development-kit
    ```

#### From self-managed dependencies to GDK-managed dependencies using `asdf`

If you've previously [managed your own dependencies](advanced.md), you might want to let
[GDK manage dependencies for you using `asdf`](migrate_to_asdf.md).

### Install GDK

Install GDK by cloning and configuring GitLab and other projects using
`gdk install`. Use one of the following methods:

- For those who have write access to the [GitLab.org group](https://gitlab.com/gitlab-org) we
  recommend installing via SSH:

    ```shell
    gdk install gitlab_repo=git@gitlab.com:gitlab-org/gitlab.git
    ```

- Otherwise:

    ```shell
    gdk install
    ```

  Use `gdk install shallow_clone=true` for a faster clone that consumes less disk-space.
  The clone process uses [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

### Install GDK using GitLab FOSS project

Install GDK using [the GitLab FOSS project](doc/install_alternatives.md#install-using-gitlab-foss-project).

### Install GDK using your own GitLab fork

Install GDK using [your own GitLab fork](doc/install_alternatives.md#install-using-your-own-gitlab-fork).

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

1. Restart GDK to use the new configuration:

   ```shell
   gdk restart
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
