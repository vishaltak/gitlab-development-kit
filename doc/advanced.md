# Advanced dependency instructions

The following are dependency installation instructions for systems other than
those covered in the [main dependency installation instructions](index.md#install-dependencies).

These instructions may contain advanced configuration options.

## macOS

GDK supports macOS 10.13 (High Sierra) and later. To install dependencies for macOS:

1. [Install](https://brew.sh) Homebrew to get access to the `brew` command for package management.
1. Clone the [`gitlab-development-kit` project](https://gitlab.com/gitlab-org/gitlab-development-kit)
   so you have access to the project's
   [`Brewfile`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/Brewfile).
   You can:
     - Reuse an existing checkout if you have one, but make sure it's up to date.
     - Use this check out again when you [install and set up GDK](index.md#install-and-set-up-gdk).
1. In the `gitlab-development-kit` checkout, run the following `brew` commands:

   ```shell
   brew bundle
   brew install git go postgresql@12 minio/stable/minio rbenv redis yarn
   ```

1. Add `/usr/local/opt/postgresql@12/bin` to your shell's `PATH` environment variable.
1. [Configure `rbenv`](https://github.com/rbenv/rbenv#homebrew-on-macos) for your shell.
1. Install [`nvm`](https://github.com/nvm-sh/nvm#installing-and-updating), and configure it for your
   shell.

## Ubuntu

NOTE: These instructions don't account for using `asdf` for managing some dependencies.

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
   # This PPA contains an up-to-date version of git
   sudo add-apt-repository ppa:git-core/ppa
   sudo apt-get install libpq-dev libicu-dev cmake g++ libre2-dev libkrb5-dev \
     libsqlite3-dev libreadline-dev libz-dev pkg-config graphicsmagick libimage-exiftool-perl \
     libssl-dev libpcre2-dev git git-lfs rsync runit curl tzdata
   [[ $(lsb_release -sr) < "18.10" ]] && sudo apt-get install g++-8
   ```

   > ℹ️ Ubuntu 18.04 (Bionic Beaver) and beyond doesn't have `python-software-properties` as a separate package.

## Debian

For Debian there are two ways to manage dependencies, either:

- Using `asdf`.
- Managing all dependencies yourself.

### Manage dependencies using `asdf`

To install some dependencies for Debian and use `asdf`:

1. Install base dependencies:

   ```shell
   sudo apt-get update && sudo apt-get install libicu-dev cmake g++ libkrb5-dev libre2-dev ed \
     pkg-config graphicsmagick runit libimage-exiftool-perl rsync libsqlite3-dev
   ```

1. [Complete dependency installation](index.md#install-and-set-up-gdk) using `asdf`.

### Manage dependencies yourself

To install dependencies for Debian and manage them yourself:

1. Run the following commands:

   ```shell
   sudo apt-get update && sudo apt-get install postgresql postgresql-contrib libpq-dev redis-server \
     libicu-dev cmake g++ libkrb5-dev libre2-dev ed pkg-config graphicsmagick \
     runit libimage-exiftool-perl rsync libsqlite3-dev
   sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
   sudo chmod +x /usr/local/bin/minio
   ```

1. Install Go:
   - If you're running Debian [Experimental](https://wiki.debian.org/DebianExperimental) or
     [newer](https://packages.debian.org/search?keywords=golang-go), you can install a Go compiler
    using your package manager: `sudo apt-get install golang`.
   - Otherwise, install it manually. See the [Go](https://golang.org/doc/install#install) official
     installation instructions.
1. Install [Redis](https://redis.io) 5.0 or newer manually, if you don't already have it.
1. Install Ruby using [`rbenv`](https://github.com/rbenv/rbenv).

## Install Other Linux dependencies

The process for installing dependencies on Linux depends on your Linux
distribution.

Unless already set, you might have to increase the watches limit of
`inotify` for frontend development tools such as `webpack` to effectively track
file changes. See [Inotify Watches Limit](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
for details and instructions about how to apply this change.

### Arch Linux

NOTE: These instructions don't account for using `asdf` for managing some dependencies.

To install dependencies for Arch Linux:

```shell
pacman -S postgresql redis postgresql-libs icu npm ed cmake openssh git git-lfs go re2 \
  unzip graphicsmagick perl-image-exiftool rsync yarn minio sqlite python2
```

NOTE:
The Arch Linux core repository no longer contains the `runit` package. You must
install `runit-systemd` from the Arch User Repository (AUR) with an AUR package
manager, such as `pacaur` ([https://github.com/E5ten/pacaur](https://github.com/E5ten/pacaur))
or `pikaur` ([https://github.com/actionless/pikaur](https://github.com/actionless/pikaur)).
For more information, see [Arch Linux Wiki page AUR_helpers](https://wiki.archlinux.org/index.php/AUR_helpers).

```shell
pikaur -S runit-systemd
```

### Fedora

NOTE: These instructions don't account for using `asdf` for managing some dependencies.

We assume you are using Fedora >= 31.

NOTE:
Fedora 32 ships PostgreSQL 11.x and Fedora 32+ ships PostgreSQL 12.x in default repositories.
You can use `postgresql:11` or `postgresql:12` module to install PostgreSQL 11 or 12.
But keep in mind that replaces the default version of PostgreSQL package, so you cannot
use both versions at once.

```shell
sudo dnf module enable postgresql:12 # or postgresql:11
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

#### runit

You also need to install [runit](http://smarden.org/runit) manually.

Although the following instructions work for runit version 2.1.2, be sure to
read the up-to-date installation instructions on [the website](http://smarden.org/runit)
before continuing.

1. Download and extract the runit source code to a local folder to compile it:

   ```shell
   wget http://smarden.org/runit/runit-2.1.2.tar.gz
   tar xzf runit-2.1.2.tar.gz
   cd admin/runit-2.1.2
   sed -i -E 's/ -static$//g' src/Makefile
   ./package/compile
   ./package/check
   ```

1. Ensure all binaries in `command/` are accessible from your `PATH` (for
   example, symlink / copy them to `/usr/local/bin`)

### CentOS

NOTE: These instructions don't account for using `asdf` for managing some dependencies.

We assume you are using CentOS >= 8.

To install dependencies for CentOS (tested on CentOS 8.2):

```shell
sudo dnf module enable postgresql:12
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install postgresql-server postgresql-devel libicu-devel git git-lfs cmake \
  gcc-c++ go redis ed fontconfig freetype libfreetype.so.6 libfontconfig.so.1 \
  libstdc++.so.6 npm re2 re2-devel GraphicsMagick perl-Image-ExifTool \
  rsync sqlite-devel
sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio

# This example uses Ruby 2.7.2. Substitute with the current version if different.
sudo rvm install 2.7.2
sudo rvm use 2.7.2
#Ensure your user is in rvm group
sudo usermod -a -G rvm <username>
#add iptables exceptions, or sudo service stop iptables
```

You need to follow [runit install instruction](#runit) to install it manually.

### OpenSUSE

NOTE: These instructions don't account for using `asdf` for managing some dependencies.

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

Setup local Ruby 2.6 environment (see [Ruby](#ruby) for details), for example
using [RVM](https://rvm.io/):

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

Now determine that the current Ruby version is 2.7.x:

```shell
ruby --version
ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-linux]
```

If it's different (for example Ruby 2.7 - system default in Tumbleweed), you
must sign in again.

The following `bundle config` options are recommended before you run
`gdk install` to avoid problems with the embedded libraries inside `nokogiri`
and `gpgme`:

```shell
bundle config build.nokogiri "--use-system-libraries" --global
bundle config build.gpgme --use-system-libraries
```

Now you can proceed to [set up GDK](index.md).

## Install FreeBSD dependencies

To install dependencies for FreeBSD:

```shell
sudo pkg install postgresql10-server postgresql10-contrib postgresql-libpqxx \
redis go node icu krb5 gmake re2 GraphicsMagick p5-Image-ExifTool git-lfs minio sqlite3
```

## Install Windows 10 dependencies

> 🚨 Support for Windows 10 became stable with the introduction of the Windows Subsystem for Linux 2 (WSL2) in version 2004.

**Setting up the Windows Subsystem for Linux:**

Open PowerShell as Administrator and run:

```shell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
wsl --set-default-version 2
```

Restart your computer when prompted.

Install your Linux distribution of choice using the Windows Store. The available
distribution options include:

- Ubuntu
- OpenSUSE
- SLES
- Kali Linux
- Debian GNU/Linux

Launch the distribution of choice.

You must ensure that your Linux distribution uses WSL version 2. Open PowerShell
with administrator privileges, and then run the following:

```shell
# If the command below does not return a list of your installed distributions,
# you have WS1.
wsl -l
```

You can [upgrade](https://docs.microsoft.com/en-us/windows/wsl/wsl2-kernel) your
WSL.

If you noticed your distribution of choice is an older subsystem, you can
upgrade it by running:

```shell
# Get the name of your subsystem
wsl -l
# Run the following command
wsl --set-version <your subsystem name here>
```

## Next Steps

After you've completed the steps on this page, [install and set up GDK](index.md).
