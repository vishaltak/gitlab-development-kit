#!/bin/bash

set -xeuo pipefail
IFS=$'\n\t'

echo "# --- Install GDK into /workspace "
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

# Rails settings
# Disable bootsnap as it can cause temporary/cache files to remain, resulting
# in Docker image creation to fail
gdk config set gitlab.rails.bootsnap false
gdk config set gitlab.rails.port 443
gdk config set gitlab.rails.https.enabled true

# Webpack settings
gdk config set webpack.host 127.0.0.1
gdk config set webpack.static false
gdk config set webpack.live_reload false

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

echo "# --- Cleanup build caches"
sudo rm -rf "$HOME/gitlab-development-kit/gitaly/_build/deps/git/source"
sudo rm -rf "$HOME/gitlab-development-kit/gitaly/_build/deps/libgit2/source"
sudo rm -rf "$HOME/gitlab-development-kit/gitaly/_build/cache"
sudo rm -rf "$HOME/.cache/"
sudo rm -rf /tmp/*

# Cleanup temporary build folder
sudo rm -rf /workspace
