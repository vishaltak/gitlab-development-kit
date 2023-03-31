# shellcheck shell=bash

BASE_PATH="$(pwd)"
GDK_CHECKOUT_PATH="${HOME}/gdk"

if [[ ${GDK_DEBUG} == "1" ]]; then
  export GIT_CURL_VERBOSE=1
fi

cd_into_base_path() {
  cd "${BASE_PATH}" || exit
}

cd_into_checkout_path() {
  cd "${GDK_CHECKOUT_PATH}/${1}" || exit
}

init() {
  os=$(uname -s)
  maxfiles=1048576

  if [ "${os}" == "Darwin" ]; then
    sudo /usr/sbin/sysctl -w kern.maxfiles=${maxfiles}
  elif [ "${os:0:5}" == "Linux" ]; then
    sudo /sbin/sysctl fs.inotify.max_user_watches=${maxfiles}
  fi

  install_gdk_clt
}

install_gdk_clt() {
  if [[ "$("${GDK_CHECKOUT_PATH}/bin/gdk" config get gdk.use_bash_shim)" == "true" ]]; then
    echo "INFO: Installing gdk shim.."
    install_shim
  else
    echo "INFO: Installing gitlab-development-kit Ruby gem.."
    install_gem
  fi
}

install_shim() {
  cp -f "${GDK_CHECKOUT_PATH}/bin/gdk" /usr/local/bin
}

install_gem() {
  cd_into_checkout_path "gem"

  gem build gitlab-development-kit.gemspec
  gem install gitlab-development-kit-*.gem
}

checkout() {
  cd_into_checkout_path

  # $CI_MERGE_REQUEST_SOURCE_PROJECT_URL only exists in pipelines generated in merge requests.
  if [ -n "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}" ]; then
    git remote set-url origin "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}.git"
  fi

  git fetch
  git checkout "${1}"
}

set_gitlab_upstream() {
  cd_into_checkout_path "gitlab"

  local remote_name
  local default_branch

  remote_name="upstream"
  default_branch="master"

  if git remote | grep -Eq "^${remote_name}$"; then
    echo "Remote ${remote_name} already exists in $(pwd)."
    return
  fi

  git remote add "${remote_name}" "https://gitlab.com/gitlab-org/gitlab.git"

  git remote set-url --push "${remote_name}" none # make 'upstream' fetch-only
  echo "Fetching ${default_branch} from ${remote_name}..."

  git fetch "${remote_name}" ${default_branch}

  # check if the default branch already exists
  if git show-ref --verify --quiet refs/heads/${default_branch}; then
    git branch --set-upstream-to="${remote_name}/${default_branch}" ${default_branch}
  else
    git branch ${default_branch} "${remote_name}/${default_branch}"
  fi
}

install() {
  cd_into_checkout_path

  echo "> Installing GDK.."
  gdk install
  set_gitlab_upstream
}

update() {
  cd_into_checkout_path

  echo "> Updating GDK.."
  # we use `make update` instead of `gdk update` to ensure the working directory
  # is not reset to the default branch.
  make update
  set_gitlab_upstream
  restart
}

reconfigure() {
  cd_into_checkout_path

  echo "> Running gdk reconfigure.."
  gdk reconfigure
}

reset_data() {
  cd_into_checkout_path

  echo "> Running gdk reset-data.."
  gdk reset-data
}

pristine() {
  cd_into_checkout_path

  echo "> Running gdk pristine.."
  gdk pristine
}

start() {
  cd_into_checkout_path

  echo "> Starting up GDK.."
  gdk start
}

stop() {
  cd_into_checkout_path

  echo "> Stopping GDK.."

  # shellcheck disable=SC2009
  ps -ef | grep "[r]unsv" || true

  GDK_KILL_CONFIRM=true gdk kill || true

  # shellcheck disable=SC2009
  ps -ef | grep "[r]unsv" || true
}

restart() {
  cd_into_checkout_path

  echo "> Restarting GDK.."

  stop_start

  echo "> Upgrading PostgreSQL data directory if necessary.."
  support/upgrade-postgresql

  stop_start
}

stop_start() {
  cd_into_checkout_path

  stop
  status
  start
}

status() {
  cd_into_checkout_path

  echo "> Running gdk status.."
  gdk status || true
}

doctor() {
  cd_into_checkout_path

  echo "> Running gdk doctor.."
  gdk doctor || true
}

test_url() {
  cd_into_checkout_path

  sleep 60

  status

  # QUIET=false support/test_url || QUIET=false support/test_url
  support/ci/test_url
}

setup_geo() {
  sudo /sbin/sysctl fs.inotify.max_user_watches=524288

  if [ -n "${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}" ]; then
    sha="${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}"
  else
    sha="${CI_COMMIT_SHA}"
  fi

  cd ..
  GITLAB_LICENSE_MODE=test CUSTOMER_PORTAL_URL="https://customers.staging.gitlab.com" gdk/support/geo-install gdk gdk2 "${sha}"
  output=$(cd gdk2/gitlab && bin/rake gitlab:geo:check)

  matchers=(
    "GitLab Geo is enabled ... yes"
    "This machine's Geo node name matches a database record ... yes, found a secondary node named \"gdk2\""
    "GitLab Geo tracking database is correctly configured ... yes"
    "Database replication enabled? ... yes"
    "Database replication working? ... yes"
  )

  for matcher in "${matchers[@]}"; do
    if [[ $output != *${matcher}* ]]; then
      echo "Geo install failed. The string is not found: ${matcher}"
      exit 1
    fi
  done
}

#
# MacOS specific functions
#

macos_system_info() {
  uname -a
  arch
  brew --prefix
  env
}

macos_uninstall_asdf() {
  rm -rf "${ASDF_DATA_DIR:-$HOME/.asdf}"
  rm -rf "$HOME/.tool-versions" "$HOME/.asdfrc"

  sed "/. \$HOME\/.asdf\/asdf.sh/d" "$HOME/.zshrc" > "$HOME/.zshrc.tmp" && mv "$HOME/.zshrc.tmp" "$HOME/.zshrc"
  unset ASDF_DATA_DIR
  unset ASDF_DIR
}

macos_install_rvm() {
  gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  \curl -sSL https://get.rvm.io | bash -s stable --autolibs=homebrew

  # Load RVM in order to use it inside the script
  # shellcheck disable=SC1090
  source "${HOME}/.rvm/scripts/rvm"

  # Symlink to the project folder so it can be cached
  ln -s "${HOME}/.rvm" "$RVM_PATH"
}

macos_install_rvm_ruby() {
  # RVM will compile ruby for the first time and then cache it
  # to just install the pre-compiled version if we run `rvm prepare`
  ruby_version=$1

  rvm install "${ruby_version}"

  # Install Ruby
  rvm use "${ruby_version}" --default
  cd_into_base_path
}
