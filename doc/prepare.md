# Prepare your system for GDK

Before [setting up GDK](index.md), your local environment must have prerequisite third-party
software installed and configured. Some dependencies can be installed with a "package manager".

You should regularly keep these dependencies up to date. Generally, the latest versions of these
dependencies work fine.

NOTE: **Note:**
Install, configure, and update all of these dependencies as a non-root user. If you don't know what
a root user is, you very likely run everything as a non-root user already.

## Install dependencies

The process for installing dependencies depends on your operating system. Instructions are available
for:

- [macOS](#install-macos-dependencies)
- [Ubuntu](#install-ubuntu-dependencies)

[Advanced instructions](prepare_advanced.md) are also available, including instructions for:

- [Other Linux distributions](prepare_advanced.md#install-linux-dependencies)
- [FreeBSD](prepare_advanced.md#install-freebsd-dependencies)
- [Windows 10](prepare_advanced#install-windows-10-dependencies)

### Install macOS dependencies

GDK supports macOS 10.13 (High Sierra) and higher. In macOS 10.15 (Catalina) the default shell
changed from [Bash](https://www.gnu.org/software/bash/) to [Zsh](http://zsh.sourceforge.net). The
differences are handled by setting a `shell_file` variable based on your current shell.

To install dependencies for macOS:

1. [Install](https://brew.sh) Homebrew to get access to the `brew` command for package management.
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
1. [Install Ruby](#install-ruby).

If ChromeDriver fails to open with an error message because the developer *cannot be verified*,
create an exception for it as documented in the
[macOS documentation](https://support.apple.com/en-gb/guide/mac-help/mh40616/mac).

NOTE: **Note:**
We strongly recommend using the default installation directory for Homebrew (`/usr/local`). This simplifies
the Ruby gems installation with C extensions. If you use a custom directory, additional work is required
when installing Ruby gems. For more information, see
[Why does Homebrew prefer I install to /usr/local?](https://docs.brew.sh/FAQ#why-does-homebrew-prefer-i-install-to-usrlocal).

### Install Ubuntu dependencies

NOTE: **Note:**
These instructions don't account for using `asdf` for managing some dependencies.

To install dependencies for Ubuntu (assuming you're using an active LTS release (16.04, 18.04, 20.04) or higher):

1. Install **Yarn** from the [Yarn Debian package repository](https://yarnpkg.com/lang/en/docs/install/#debian-stable).
1. Install remaining dependencies. Modify the `GDK_GO_VERSION` with the major.minor version number (currently 1.14) as needed:

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

## Next Steps

After you've completed the steps on this page, [install and set up GDK](index.md).
