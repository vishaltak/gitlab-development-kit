# Prepare your system for GDK

Before [setting up GDK](index.md), your local environment must have prerequisite software installed
and configured.

## Install dependencies

GDK depends on third-party software to run. Some dependencies can be installed with a
"package manager".

The following [operating system dependencies](#install-os-dependencies) should be installed using
[`brew`](https://brew.sh) for macOS or your Linux distribution's package manager:

- [`asdf`](https://asdf-vm.com/#/)
- [Git](https://git-scm.com) version 2.28 or higher
- [Git LFS](https://git-lfs.github.com) version 2.10 or higher
- [GraphicsMagick](http://www.graphicsmagick.org)
- [Exiftool](https://exiftool.org)
- [runit](http://smarden.org/runit/)
- [Google Chrome](https://www.google.com/chrome/) version 60 or higher. Many users will have
  installed this already without a package manager
- [ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/downloads) version 2.33 or
  higher

You should regularly keep these dependencies up to date. Generally, the latest versions of these
dependencies work fine.

We recommend installing the following [additional dependencies](#install-additional-dependencies) with
[`asdf`](https://asdf-vm.com/#/core-manage-asdf-vm) for both macOS and Linux:

- [Ruby](https://www.ruby-lang.org)
- [Node.js](https://nodejs.org)
- [Yarn](https://yarnpkg.com)
- [PostgreSQL](https://www.postgresql.org)
- [Go](https://golang.org)
- [MinIO](https://min.io)
- [Redis](https://redis.io)

`asdf` alerts you when these dependencies fall out of date compared to the project's
[`.tool-versions`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/.tool-versions)
file. You should not update beyond the versions specified in this project.

**Note:**
Install, configure, and update all of these dependencies as a non-root user. If you don't know what
a root user is, you very likely run everything as a non-root user already.

### Install OS dependencies

The process for installing operating system dependencies depends on your operating system.

#### Install macOS dependencies

GDK supports macOS 10.13 (High Sierra) and higher. In macOS 10.15 (Catalina) the default shell
changed from [Bash](https://www.gnu.org/software/bash/) to [Zsh](http://zsh.sourceforge.net). The
differences are handled by setting a `shell_file` variable based on your current shell.

To install dependencies for macOS:

1. [Install](https://brew.sh) `brew`.
1. Run the following `brew` commands:

   ```shell
   brew install asdf git git-lfs libiconv pkg-config cmake openssl coreutils re2 graphicsmagick gpg icu4c exiftool sqlite
   brew link pkg-config
   brew pin libffi icu4c readline re2
   if [ ${ZSH_VERSION} ]; then shell_file="${HOME}/.zshrc"; else shell_file="${HOME}/.bash_profile"; fi
   echo 'export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ${shell_file}
   source ${shell_file}
   brew cask install google-chrome chromedriver
   ```

1. Follow any post-installation instructions that are provided. For example, `asdf` has
   [post-install instructions](https://asdf-vm.com/#/core-manage-asdf-vm?id=add-to-your-shell).

If ChromeDriver fails to open with an error message because the developer "cannot be verified",
create an exception for it as documented in
[macOS documentation](https://support.apple.com/en-gb/guide/mac-help/mh40616/mac).

NOTE: **Note:**
We strongly recommend using the default installation directory for `brew` (`/usr/local`). This makes
it a lot easier to install Ruby gems with C extensions. If you use a custom directory, you have to
do a lot of extra work when installing Ruby gems. For more information, see
[Why does Homebrew prefer I install to /usr/local?](https://docs.brew.sh/FAQ#why-does-homebrew-prefer-i-install-to-usrlocal).

#### Install Linux dependencies

The process for installing dependencies on Linux depends on your Linux distribution.

Unless already set, you will likely have to increase the watches limit of `inotify` in order for
frontend development tools such as `webpack` to effectively track file changes.
See [Inotify Watches Limit](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
for details and instructions on how to apply this change.

##### Ubuntu

NOTE: **Note:**
These instructions don't account for using `asdf` for managing some dependencies.

To install dependencies for Ubuntu:

We assume you are using an active LTS release (16.04, 18.04, 20.04) or higher.

1. Install **Yarn** from the [Yarn Debian package repository](https://yarnpkg.com/lang/en/docs/install/#debian-stable).
1. Install remaining dependencies; modify the `GDK_GO_VERSION` with the major.minor version number (currently 1.14) as needed:

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
     pkg-config graphicsmagick runit libimage-exiftool-perl rsync libssl-dev
   [[ $(lsb_release -sr) < "18.10" ]] && sudo apt-get install g++-8
   sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
   sudo chmod +x /usr/local/bin/minio
   ```

   > ℹ️ Ubuntu 18.04 (Bionic Beaver) and beyond doesn't have `python-software-properties` as a separate package.

1. You're all set now. [Go to next steps](#next-steps).

##### Arch Linux

NOTE: **Note:**
These instructions don't account for using `asdf` for managing some dependencies.

To install dependencies for Arch Linux:

```shell
pacman -S postgresql redis postgresql-libs icu npm ed cmake openssh git git-lfs go re2 \
  unzip graphicsmagick perl-image-exiftool rsync yarn minio sqlite python2
```

NOTE: **Note:**
The Arch Linux core repository does not contain anymore the `runit` package. It is required to install `runit-systemd` from the Arch User Repository (AUR) with an AUR package manager like `pacaur` ([https://github.com/E5ten/pacaur](https://github.com/E5ten/pacaur)) or `pikaur` ([https://github.com/actionless/pikaur](https://github.com/actionless/pikaur)). See [Arch Linux Wiki page AUR_helpers](https://wiki.archlinux.org/index.php/AUR_helpers) for more information.

```shell
pikaur -S runit-systemd
```

##### Debian

NOTE: **Note:**
These instructions don't account for using `asdf` for managing some dependencies.

To install dependencies for Debian:

```shell
sudo apt-get install postgresql postgresql-contrib libpq-dev redis-server \
  libicu-dev cmake g++ libkrb5-dev libre2-dev ed pkg-config graphicsmagick \
  runit libimage-exiftool-perl rsync libsqlite3-dev
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

If you are running Debian [Experimental](https://wiki.debian.org/DebianExperimental), or [newer](https://packages.debian.org/search?keywords=golang-go) you can install a Go
compiler via your package manager: `sudo apt-get install golang`.
Otherwise you need to install it manually. See [Go](https://golang.org/doc/install#install) official installation
instructions.

You may need to install Redis 5.0 or newer manually.

##### Fedora

NOTE: **Note:**
These instructions don't account for using `asdf` for managing some dependencies.

We assume you are using Fedora >= 22.

If you are running Fedora < 27 you'll need to install `go` manually using [go] official installation instructions.

NOTE: **Note:**
Fedora 30+ ships PostgreSQL 11.x in default repositories, you can use `postgresql:10` module to install PostgreSQL 10.
But keep in mind that will replace the PostgreSQL 11.x package, so you cannot use both versions at once.

```shell
sudo dnf install fedora-repos-modular
sudo dnf module enable postgresql:10
```

To install dependencies for Fedora:

```shell
sudo dnf install postgresql libpqxx-devel postgresql-libs redis libicu-devel \
  git git-lfs ed cmake rpm-build gcc-c++ krb5-devel go postgresql-server \
  postgresql-contrib re2 GraphicsMagick re2-devel sqlite-devel perl-Digest-SHA \
  perl-Image-ExifTool rsync
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

You may need to install Redis 5.0 or newer manually.

###### runit

You will also need to install [runit](http://smarden.org/runit) manually.

The following instructions worked for runit version 2.1.2 - but please make sure you read the up to date installation instructions on [the website](http://smarden.org/runit) before continuing.

1. Download and extract the runit source code to a local folder to compile it:

   ```shell
   wget http://smarden.org/runit/runit-2.1.2.tar.gz
   tar xzf runit-2.1.2.tar.gz
   cd admin/runit-2.1.2
   sed -i -E 's/ -static$//g' src/Makefile
   ./package/compile
   ./package/check
   ```

1. Make sure all binaries in `command/` are accessible from your `PATH` (e.g. symlink / copy them to `/usr/local/bin`)

##### CentOS

NOTE: **Note:**
These instructions don't account for using `asdf` for managing some dependencies.

To install dependencies for Fedora (tested on CentOS 6.5):

```shell
sudo yum install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-6-x86_64/pgdg-centos10-10-2.noarch.rpm
sudo yum install https://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo yum install postgresql10-server postgresql10-devel libicu-devel git git-lfs cmake \
  gcc-c++ redis ed fontconfig freetype libfreetype.so.6 libfontconfig.so.1 \
  libstdc++.so.6 npm re2 re2-devel GraphicsMagick runit perl-Image-ExifTool \
  rsync sqlite-devel
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio

bundle config build.pg --with-pg-config=/usr/pgsql-10/bin/pg_config
# This example uses Ruby 2.6.6. Substitute with the current version if different.
sudo rvm install 2.6.6
sudo rvm use 2.6.6
#Ensure your user is in rvm group
sudo usermod -a -G rvm <username>
#add iptables exceptions, or sudo service stop iptables
```

Install `go` manually using [go] official installation instructions.

Git 1.7.1-3 is the latest Git binary for CentOS 6.5 and GitLab. Spinach tests
will fail due to a higher version requirement by GitLab. You can follow the
instructions found [in the GitLab recipes repository](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/install/centos#add-puias-computational-repository) to install a newer
binary version of Git.

You may need to install Redis 5.0 or newer manually.

##### OpenSUSE

NOTE: **Note:**
These instructions don't account for using `asdf` for managing some dependencies.

This was tested on `openSUSE Tumbleweed (20200628)`.

> NOTE: OpenSUSE LEAP is currently not supported, because since a8e2f74d PostgreSQL 11+
> is required, but `LEAP 15.1` includes PostgreSQL 10 only.

To install dependencies for OpenSUSE:

```shell
sudo zypper dup
# now reboot with "sudo init 6" if zypper reports:
# There are running programs which still use files and libraries deleted or updated by recent upgrades.
sudo zypper install libxslt-devel postgresql postgresql-devel libpqxx-devel redis libicu-devel git git-lfs ed cmake \
        rpm-build gcc-c++ krb5-devel postgresql-server postgresql-contrib \
        libxml2-devel libxml2-devel-32bit findutils-locate GraphicsMagick \
        exiftool rsync sqlite3-devel postgresql-server-devel \
        libgpg-error-devel libqgpgme-devel yarn curl wget re2-devel
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

Install `go` manually using [Go](https://golang.org/doc/install) official installation instructions, for example:

```shell
curl -O https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz
sudo tar xpzf go1.14.4.linux-amd64.tar.gz -C /usr/local
```

Ensure that `node` has write permissions to install packages using:

```shell
mkdir -p ~/mynode/bin ~/mynode/lib
npm config set prefix ~/mynode
```

Install `runit` (it is no longer included in OpenSUSE):

```shell
wget http://smarden.org/runit/runit-2.1.2.tar.gz
tar xzf runit-2.1.2.tar.gz
cd admin/runit-2.1.2
sed -i -E 's/ -static$//g' src/Makefile
./package/compile
./package/check
sudo ./package/install
```

Setup local Ruby 2.6 environment (see [Ruby](#ruby) for details), for example using [RVM](https://rvm.io/):

```shell
curl -sSL -o setup_rvm.sh https://get.rvm.io
chmod a+rx setup_rvm.sh
./setup_rvm.sh
source  /home/ansible/.rvm/scripts/rvm
rvm install 2.6
```

Append these lines to your `~/.bashrc`:

```shell
# to find binaries installed by yarn command
export PATH="$HOME/.yarn/bin:$PATH"
# to find sshd and redis-server in default path
export PATH="$PATH:/usr/sbin"
# to find go
export PATH="$HOME/go/bin:/usr/local/go/bin:$PATH"
# local node packages
export PATH="$HOME/mynode/bin:$PATH"
# GDK is confused with OSTYPE=linux (suse default)
export OSTYPE=linux-gnu
```

And reload it using:

```shell
source ~/.bashrc
```

Now check that currenty Ruby version is 2.6.x:

```shell
ruby --version
ruby 2.6.6p146 (2020-03-31 revision 67876) [x86_64-linux]
```

If it is different (for example Ruby 2.7 - system default in Tumbleweed) you need to relogin.

The following `bundle config` options are recommended before you run `gdk install` in order to avoid problems with the embedded libraries inside `nokogiri` and `gpgme`:

```shell
bundle config build.nokogiri "--use-system-libraries" --global
bundle config build.gpgme --use-system-libraries
```

Now you can proceed to [set up GDK](index.md).

##### FreeBSD

To install dependencies for FreeBSD:

```shell
sudo pkg install postgresql10-server postgresql10-contrib postgresql-libpqxx \
redis go node icu krb5 gmake re2 GraphicsMagick p5-Image-ExifTool git-lfs minio sqlite3
```

#### Windows 10

> 🚨 Support for Windows 10 became stable with the introduction of the Windows Subsystem for Linux 2 (WSL2) in version 2004.

**Setting up the Windows Subsystem for Linux:**

Open PowerShell as Administrator and run:

```shell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
wsl --set-default-version 2
```

Restart your computer when prompted.

Install your Linux Distribution of Choice via the Windows Store. Currently the distro options are:

- Ubuntu
- OpenSUSE
- SLES
- Kali Linux
- Debian GNU/Linux

Launch the distro of choice.

You must ensure that your Linux distribution uses WSL version 2. Open PowerShell with
administrator privileges and run the following:

```shell
# If the command below does not return a list of your installed distributions,
# you have WS1.
wsl -l
```

You can [upgrade](https://docs.microsoft.com/en-us/windows/wsl/wsl2-kernel) your WSL.

If you noticed your distribution of choice is an older subsystem, you can upgrade it by
running:

```shell
# Get the name of your subsystem
wsl -l
# Run the following command
wsl --set-version <your subsystem name here>
```

### Install additional dependencies

`asdf` is a unified package manager that can install, configure, and update the additional
dependencies required by GDK.

To install additional dependencies with `asdf`, use `make bootstrap`:

```shell
make bootstrap
```

## Documentation tools

Linting for GDK documentation is performed by:

- markdownlint.
- Vale.

For more information and instructions on installing tooling and plugins for editors, see
[Linting](https://docs.gitlab.com/ee/development/documentation/#linting).

## Next Steps

After you have completed everything here, [set up GDK](index.md).
