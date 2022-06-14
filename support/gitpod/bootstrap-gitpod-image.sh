#!/bin/bash

set -xeuo pipefail
IFS=$'\n\t'

sudo apt-get update
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt-get install -y make git

# Install GitLab Runner
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
export GITLAB_RUNNER_DISABLE_SKEL=true
sudo apt-get install gitlab-runner -y

# Install GDK
sudo mkdir -p /workspace/gitlab
sudo chown -R gitpod:gitpod /workspace
cd /workspace
git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git
cd gitlab-development-kit
[[ -n "${GIT_CHECKOUT_BRANCH:-}" ]] && git checkout "${GIT_CHECKOUT_BRANCH}"
make bootstrap

# Set asdf dir correctly
ASDF_DIR="${ASDF_DIR:-${HOME}/.asdf}"
source "${ASDF_DIR}/asdf.sh"

# Disable bootsnap as it can cause temporary/cache files to remain, resulting
# in Docker image creation to fail
gdk config set gitlab.rails.bootsnap false

# make webpack static, prevents that GitLab tries to connect to localhost webpack from browser outside the workspace
gdk config set webpack.static true

cat gdk.yml

gdk install shallow_clone=true
gdk stop || true
GDK_KILL_CONFIRM=true gdk kill || true
ps -ef || true
mv gitlab/config/secrets.yml .
rm -rf gitlab/ tmp/ || true
git restore tmp
cp ./support/completions/gdk.bash "$HOME/.bashrc.d/90-gdk"
cd /workspace
mv gitlab-development-kit "$HOME/"

# Set up a symlink in order to have our .tool-versions as defaults.
# A symlink ensures that it'll work even after a gdk update
ln -s /workspace/gitlab-development-kit/.tool-versions "$HOME/.tool-versions"

# Cleanup apt caches
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# Cleanup build caches
sudo rm -rf "$HOME/gitlab-development-kit/gitaly/_build/deps/git/source"
sudo rm -rf "$HOME/gitlab-development-kit/gitaly/_build/deps/libgit2/source"
sudo rm -rf "$HOME/gitlab-development-kit/gitaly/_build/cache"
sudo rm -rf "$HOME/.cache/"
sudo rm -rf /tmp/*

# Cleanup temporary build folder
sudo rm -rf /workspace
