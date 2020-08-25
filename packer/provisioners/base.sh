#!/bin/sh

# Install the needed stack for running GDK/GitLab under ubuntu 20.04 (Focal Fossa)
# Stack:
# - rbenv
# - postgresql 11
# - golang 1.14
# - docker
# - git
# - redis
# - nodejs 12.x
# - yarn
# - runit
# - nginx
# - minio
# - zsh
# - codeserver
# - chromedriver

# postgresql 11
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list

# install dependencies
apt-add-repository -y ppa:ubuntu-lxc/lxd-stable

# git
add-apt-repository -y ppa:git-core/ppa

# node 12.x source
# wget -qO- https://deb.nodesource.com/setup_12.x | bash -

# yarn key and source
wget -qO- https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# avoid being asked for confirmation during the install process
export DEBIAN_FRONTEND=noninteractive
export RUNLEVEL=1

apt-get update

# install packages
apt-get -y install \
  golang-1.14 \
  git git-lfs \
  graphicsmagick \
  postgresql-11 \
  libpq-dev \
  libimage-exiftool-perl \
  libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev \
  redis-server \
  libicu-dev \
  cmake \
  libpcre2-dev \
  libcurl4-gnutls-dev \
  pkg-config \
  g++ \
  nodejs \
  libkrb5-dev \
  curl \
  ruby \
  ed \
  nginx \
  libgmp-dev \
  yarn \
  libre2-dev \
  docker.io \
  runit \
  net-tools \
  libnss3-dev \
  ack \
  zsh powerline fonts-powerline

# put go binary in the right place
ln -s /usr/lib/go-1.14/bin/* /usr/local/bin

# minio
curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio
chmod +x /usr/local/bin/minio

# create user and give permissions
DEV_USER=gdk
useradd $DEV_USER -m -s /usr/bin/zsh
echo "$DEV_USER ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$DEV_USER
addgroup $DEV_USER docker

# install code-server
# https://github.com/cdr/code-server/blob/master/doc/install.md
curl -fOL https://github.com/cdr/code-server/releases/download/v3.4.1/code-server_3.4.1_amd64.deb
dpkg -i code-server_3.4.1_amd64.deb
rm code-server_3.4.1_amd64.deb

# increase limit of open handles for fixing issues with vscode remote
# https://code.visualstudio.com/docs/setup/linux#_visual-studio-code-is-unable-to-watch-for-file-changes-in-this-large-workspace-error-enospc
echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf

    # {
    #   "type": "file",
    #   "source": "files/nginx.conf",
    #   "destination": "/etc/nginx/sites-enabled/default"
    # }


# chrome driver

CHROME_VERSION="83.0.4103.61-1"
CHROME_DRIVER_VERSION="83.0.4103.39"
CHROME_DEB="google-chrome-stable_${CHROME_VERSION}_amd64.deb"
CHROME_URL="https://s3.amazonaws.com/gitlab-google-chrome-stable/${CHROME_DEB}"

curl --silent --show-error --fail -O "${CHROME_URL}" && \
    dpkg -i "./${CHROME_DEB}" || true && \
    apt-get install -f -y && \
    rm -f "./${CHROME_DEB}"

##
# Install chromedriver to make it work with Selenium
#
wget -q "https://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/chromedriver_linux64.zip"
unzip chromedriver_linux64.zip -d /usr/local/bin
rm -f chromedriver_linux64.zip

# swap file
fallocate -l 8G /swapfile
dd if=/dev/zero of=/swapfile bs=1M count=8192
mkswap /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# IO tunning
# https://cloud.google.com/compute/docs/disks/optimizing-pd-performance
blockdev --setra 16384 /dev/root

# GIT
# link git away from the same path as ruby
# to avoid gitaly conflicts
# See https://gitlab.com/gitlab-org/gitaly/-/issues/3085
ln -sf /usr/bin/git /usr/local/bin/
