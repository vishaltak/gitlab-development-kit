#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

clone_gdk() {
  echo "# --- Clone GDK ---"
  sudo mkdir -p "${WORKSPACE_DIR_NAME}/gitlab"
  sudo chown -R ${WORKSPACE_USER}:${WORKSPACE_USER} "${WORKSPACE_DIR_NAME}"
  cd "${WORKSPACE_DIR_NAME}"
  git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git
}

configure_gdk() {
  echo "# --- Configure GDK ---"
  cd "${WORKSPACE_DIR_NAME}/gitlab-development-kit"

  # Set remote origin URL if available
  if [[ -n "${GIT_REMOTE_ORIGIN_URL:-}" ]]; then
    git remote set-url origin "${GIT_REMOTE_ORIGIN_URL}.git"
    git fetch
  fi

  [[ -n "${GIT_CHECKOUT_BRANCH:-}" ]] && git checkout "${GIT_CHECKOUT_BRANCH}"

  make bootstrap

  # Set asdf dir correctly
  ASDF_DIR="${ASDF_DIR:-${HOME}/.asdf}"
  # shellcheck source=/workspace/.asdf/asdf.sh
  source "${ASDF_DIR}/asdf.sh"

  configure_rails
  configure_webpack
  cat gdk.yml
}

configure_rails() {
  echo "# --- Configure Rails settings ---"
  # Disable bootsnap as it can cause temporary/cache files to remain, resulting
  # in Docker image creation to fail.
  gdk config set gitlab.rails.bootsnap false
  gdk config set gitlab.rails.port 443
  gdk config set gitlab.rails.https.enabled true
}

configure_webpack() {
  echo "# --- Configure Webpack settings ---"
  gdk config set webpack.host 127.0.0.1
  gdk config set webpack.live_reload false
  gdk config set webpack.sourcemaps false
}

install_gdk() {
  echo "# --- Install GDK ---"
  gdk install shallow_clone=true
  gdk stop || true
  GDK_KILL_CONFIRM=true gdk kill || true
  ps -ef || true
  mv gitlab/config/secrets.yml .
  rm -rf gitlab/ tmp/ || true
  git restore tmp
  sudo cp ./support/completions/gdk.bash "/etc/profile.d/90-gdk"
  cd "${WORKSPACE_DIR_NAME}"

  # Set up a symlink in order to have our .tool-versions as defaults.
  # A symlink ensures that it'll work even after a gdk update.
  ln -s "${WORKSPACE_DIR_NAME}/gitlab-development-kit/.tool-versions" "${HOME}/.tool-versions"
}

set_permissions() {
  sudo chgrp -R 0 "${WORKSPACE_DIR_NAME}"
  sudo chmod -R g=u "${WORKSPACE_DIR_NAME}"
  sudo chmod g-w "${WORKSPACE_DIR_NAME}/gitlab-development-kit/postgresql/data"
}

cleanup() {
  echo "# --- Cleanup build caches ---"
  # Logged issue https://gitlab.com/gitlab-org/gitaly/-/issues/5459 to provide make
  # target in Gitaly to clean this up reliably
  sudo rm -rf "${WORKSPACE_DIR_NAME}/gitlab-development-kit/gitaly/_build/deps/libgit2/source"
  sudo rm -rf "${WORKSPACE_DIR_NAME}/gitlab-development-kit/gitaly/_build/cache"
  sudo rm -rf "${WORKSPACE_DIR_NAME}/gitlab-development-kit/gitaly/_build/deps"
  sudo rm -rf "${WORKSPACE_DIR_NAME}/gitlab-development-kit/gitaly/_build/intermediate"
  sudo rm -rf /tmp/*
}

clone_gdk
configure_gdk
install_gdk
set_permissions
cleanup
