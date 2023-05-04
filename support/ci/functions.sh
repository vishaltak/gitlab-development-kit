# shellcheck shell=bash

GDK_CHECKOUT_PATH="${HOME}/gdk"

if [[ ${GDK_DEBUG} == "1" ]]; then
  export GIT_CURL_VERBOSE=1
fi

cd_into_checkout_path() {
  cd "${GDK_CHECKOUT_PATH}/${1}" || exit
}

init() {
  sudo /sbin/sysctl fs.inotify.max_user_watches=524288

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
